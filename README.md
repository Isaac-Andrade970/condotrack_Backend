# condotrack_Backend

Backend del proyecto CondoTrack (tareas 0 a 3). API en **Ruby on Rails 8.1** (modo API)
con **PostgreSQL**.

## Requisitos

- Ruby 3.3.7 (ver `.ruby-version`)
- PostgreSQL corriendo localmente (o `DATABASE_URL` apuntando a uno)
- Bundler

## Correr en local

```bash
bundle install
bin/rails db:create db:migrate
bin/rails server
```

La app queda en `http://localhost:3000`.

Endpoints base:

- `GET /health` -> `200 {"status":"ok","service":"condotrack-backend","time":"..."}` (usado por el pipeline)
- `GET /up` -> health check por defecto de Rails

## Tests, lint y seguridad

```bash
bin/rails test
bin/rubocop
bin/brakeman --no-pager
bin/bundler-audit
```

Con PostgreSQL en Docker (sin instalarlo localmente):

```bash
docker run -d --name condotrack-db -p 5433:5432 -e POSTGRES_PASSWORD=postgres postgres:16-alpine
DATABASE_URL=postgres://postgres:postgres@localhost:5433 bin/rails db:test:prepare test
```

## Docker

```bash
docker build -t condotrack-backend .
docker run -d --name condotrack-backend -p 3000:80 \
  -e RAILS_MASTER_KEY=<contenido de config/master.key> \
  -e DATABASE_URL=postgres://user:pass@host:5432/condotrack_backend_production \
  condotrack-backend
```

El contenedor escucha en el puerto **80** (Thruster delante de Puma).

## CI/CD (Jenkins)

La unica CI del repo es Jenkins (no hay workflows de GitHub Actions). Para que el estado de
cada build aparezca como *check* en los PRs de GitHub, el job Multibranch necesita una
credencial de GitHub (usuario + token) en **Branch Sources -> GitHub -> Credentials**;
sin ella Jenkins usa la API anonima, no puede publicar estados y choca con el rate limit.

Job: <https://jenkins.frubilarz.cl/job/condotrack-backend/> (Multibranch Pipeline sobre
este repo; cada rama y PR obtiene su propio pipeline a partir del `Jenkinsfile`).

Etapas que corren en **todas las ramas**:

1. **Checkout**
2. **Test DB** - levanta un PostgreSQL efimero (`postgres:16-alpine`) en la red `course-net`
3. **Install deps** - `bundle install` dentro de `ruby:3.3.7-slim` (gems cacheadas en el volumen `condotrack-backend-bundle`)
4. **Lint** - `bin/rubocop`
5. **Security** - `bin/brakeman` + `bin/bundler-audit`
6. **Test** - `bin/rails db:test:prepare test`
7. **Build image** - `docker build`

Solo en la rama **`production`**:

8. **Deploy** - reemplaza el contenedor `condotrack-backend`, publicado en `127.0.0.1:4100`
9. **Migrate** - `bin/rails db:migrate` dentro del contenedor
10. **Health Check** - `curl -f http://127.0.0.1:4100/health`

El PostgreSQL de test se destruye siempre al terminar el build (`post { always }`).

### Credenciales requeridas en Jenkins (solo para deploy)

| ID | Tipo | Valor |
|---|---|---|
| `condotrack-backend-rails-master-key` | Secret text | contenido de `config/master.key` |
| `condotrack-backend-database-url` | Secret text | `postgres://user:pass@host:5432/condotrack_backend_production` |

Sin ellas el stage **Deploy** falla; las demas etapas no las necesitan.
