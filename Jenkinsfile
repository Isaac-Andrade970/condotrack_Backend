// CI/CD de condotrack_Backend (Rails 8 API + PostgreSQL) para jenkins.frubilarz.cl.
//
// El servidor Jenkins tiene un solo executor y Docker disponible. Todas las etapas
// de CI corren dentro de contenedores efimeros conectados a la red Docker externa
// `course-net`; la base de datos de test es un contenedor PostgreSQL levantado
// por build y destruido al terminar (no depende de ninguna DB compartida).
//
// Flujo:
//   Checkout -> Test DB -> Install deps -> Lint -> Security -> Test -> Build image
//   (solo rama `production`) -> Deploy -> Health Check (el entrypoint migra al arrancar)
pipeline {
    agent any

    options {
        disableConcurrentBuilds()
        timeout(time: 30, unit: 'MINUTES')
        buildDiscarder(logRotator(numToKeepStr: '20'))
    }

    environment {
        RAILS_ENV        = 'test'
        DOCKER_NETWORK   = 'course-net'
        APP_NAME         = 'condotrack-backend'
        POSTGRES_IMAGE   = 'postgres:16-alpine'
        RUBY_IMAGE       = 'ruby:3.3.7-slim'
        BUNDLE_VOLUME    = 'condotrack-backend-bundle'
        DEPLOY_PORT      = '4100'
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
                script {
                    def safeBranch = env.BRANCH_NAME.replaceAll(/[^A-Za-z0-9_.-]/, '-').toLowerCase()
                    env.SAFE_BRANCH  = safeBranch
                    env.DB_CONTAINER = "${APP_NAME}-test-db-${safeBranch}-${env.BUILD_NUMBER}"
                    env.IMAGE_TAG    = "${APP_NAME}:${safeBranch}-${env.BUILD_NUMBER}"
                }
            }
        }

        stage('Test DB') {
            steps {
                sh '''
                    docker rm -f "$DB_CONTAINER" >/dev/null 2>&1 || true
                    docker run -d --name "$DB_CONTAINER" --network "$DOCKER_NETWORK" \
                      -e POSTGRES_USER=postgres -e POSTGRES_PASSWORD=postgres \
                      "$POSTGRES_IMAGE"
                    for i in $(seq 1 30); do
                      if docker exec "$DB_CONTAINER" pg_isready -U postgres >/dev/null 2>&1; then
                        echo "PostgreSQL listo"; exit 0
                      fi
                      sleep 1
                    done
                    echo "PostgreSQL no respondio a tiempo"; docker logs "$DB_CONTAINER"; exit 1
                '''
            }
        }

        stage('Build & Test') {
            environment {
                DATABASE_URL = "postgres://postgres:postgres@${env.DB_CONTAINER}:5432"
                BUNDLE_PATH  = '/usr/local/bundle'
            }
            steps {
                script {
                    docker.image(env.RUBY_IMAGE).inside("--network ${env.DOCKER_NETWORK} -u root:root -v ${env.BUNDLE_VOLUME}:/usr/local/bundle") {
                        stage('Install deps') {
                            sh '''
                                apt-get update -qq
                                apt-get install -y -qq --no-install-recommends build-essential libpq-dev libvips git curl >/dev/null
                                gem install bundler -v "$(tail -1 Gemfile.lock | tr -d ' ')" --no-document >/dev/null
                                bundle config set --local without ""
                                bundle install --jobs 4 --retry 3
                            '''
                        }
                        stage('Lint') {
                            sh 'bin/rubocop'
                        }
                        stage('Security') {
                            sh 'bin/brakeman --no-pager'
                            sh 'bin/bundler-audit'
                        }
                        stage('Test') {
                            sh 'bin/rails db:test:prepare'
                            sh 'bin/rails test'
                        }
                    }
                }
            }
        }

        stage('Build image') {
            steps {
                sh 'docker build -t "$IMAGE_TAG" -t "$APP_NAME:$SAFE_BRANCH" .'
            }
        }

        stage('Deploy') {
            when { branch 'production' }
            steps {
                withCredentials([
                    string(credentialsId: 'condotrack-backend-rails-master-key', variable: 'RAILS_MASTER_KEY'),
                    string(credentialsId: 'condotrack-backend-database-url',     variable: 'PROD_DATABASE_URL')
                ]) {
                    sh '''
                        docker rm -f "$APP_NAME" || true
                        docker run -d \
                          --name "$APP_NAME" \
                          --network "$DOCKER_NETWORK" \
                          --restart unless-stopped \
                          -p 127.0.0.1:$DEPLOY_PORT:80 \
                          -e RAILS_ENV=production \
                          -e RAILS_MASTER_KEY="$RAILS_MASTER_KEY" \
                          -e DATABASE_URL="$PROD_DATABASE_URL" \
                          "$IMAGE_TAG"
                    '''
                }
            }
        }

        stage('Health Check') {
            when { branch 'production' }
            steps {
                // Las migraciones las corre bin/docker-entrypoint (`rails db:prepare`) antes
                // de levantar `rails server`. No se lanza un `docker exec db:migrate` aparte:
                // en el droplet de 2 GB dos boots de Rails en paralelo terminan con uno
                // matado por memoria (exit 137, build production #6). Si db:prepare falla,
                // el contenedor muere y este health check falla el build igual.
                sh '''
                    for i in $(seq 1 40); do
                      if curl -fsS "http://127.0.0.1:$DEPLOY_PORT/health"; then echo; exit 0; fi
                      sleep 3
                    done
                    docker logs --tail 50 "$APP_NAME"; exit 1
                '''
            }
        }
    }

    post {
        always {
            sh 'docker rm -f "$DB_CONTAINER" >/dev/null 2>&1 || true'
            sh 'docker image prune -f --filter "label=service=$APP_NAME" >/dev/null 2>&1 || true'
        }
    }
}
