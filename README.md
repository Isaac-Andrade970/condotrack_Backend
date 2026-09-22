# condotrack_Backend

Backend del proyecto CondoTrack (tareas 0 a 3). API en **Ruby on Rails 8.1** (modo API)
con **PostgreSQL**.

## Problema que resuelve

En condominios y edificios, los residentes reportan fallas (ascensores, filtraciones,
luminarias, ruidos molestos, áreas comunes dañadas) por canales informales — WhatsApp,
conversaciones con el conserje, un cuaderno físico — sin trazabilidad ni métricas. Este
backend expone la API REST que permite a los residentes reportar incidencias y a
conserjería/administración gestionarlas desde un panel centralizado. En esta etapa
(Tarea 1) no hay roles diferenciados: cualquier usuario autenticado puede operar los
3 recursos.

## Arquitectura

```
┌─────────────────────┐
│   Web Frontend       │
│   React (Vite)        │
└──────────┬───────────┘
           │ REST / JSON (JWT en header Authorization)
           ▼
┌─────────────────────┐
│   Backend             │
│   Ruby on Rails 8.1    │  (API-only, sin vistas)
└──────────┬───────────┘
           ▼
┌─────────────────────┐
│   PostgreSQL           │
└─────────────────────┘
```

El backend no mantiene sesión de servidor: autentica cada request vía JWT firmado con
`Rails.application.secret_key_base` (`app/lib/json_web_token.rb`), decodificado en
`ApplicationController#authenticate_request`.

## Modelo de datos

```
User (residentes/conserjería, sin roles todavía)
 │ email:string único · password_digest:string · nombre:string
 │
 │ 1:N
 ▼
Reporte
 │ titulo:string · descripcion:text
 │ estado:string (pendiente | en_progreso | resuelto)
 │ torre_unidad:string
 │ categoria_id (FK) · usuario_id (FK)
 │
 ├── N:1 → Categoria (nombre:string único · descripcion:text)
 │
 │ 1:N
 ▼
Comentario
  contenido:text · reporte_id (FK) · usuario_id (FK)
```

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

## Endpoints de la API

- `POST /signup`, `POST /login`, `GET /me` — autenticación
- `GET/POST /categorias`, `PATCH/DELETE /categorias/:id`
- `GET/POST /reportes`, `GET/PATCH/DELETE /reportes/:id`
- `GET/POST /reportes/:reporte_id/comentarios`, `DELETE /reportes/:reporte_id/comentarios/:id`

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

8. **Deploy** - reemplaza el contenedor `condotrack-backend`, publicado en `127.0.0.1:4100`.
   Las migraciones las corre `bin/docker-entrypoint` (`rails db:prepare`) al arrancar; no hay
   un stage Migrate aparte porque dos boots de Rails en paralelo agotan la memoria del droplet.
9. **Health Check** - `curl -f http://127.0.0.1:4100/health`, esperando hasta 240 s (un arranque
   en frio puede pasar de 2 min) y cortando de inmediato si el contenedor muere.

El PostgreSQL de test se destruye siempre al terminar el build (`post { always }`).

### Credenciales requeridas en Jenkins (solo para deploy)

| ID | Tipo | Valor |
|---|---|---|
| `condotrack-backend-rails-master-key` | Secret text | contenido de `config/master.key` (32 caracteres hex, sin salto de linea) |
| `condotrack-backend-database-url` | Secret text | `postgres://user:pass@host:5432` (el nombre de base al final es opcional y se ignora, ver abajo) |

Sin ellas el stage **Deploy** falla; las demas etapas no las necesitan.

#### Base de datos de produccion

En produccion la app usa **cuatro bases** en el mismo PostgreSQL (Solid Cache / Queue / Cable):
`condotrack_backend_production`, `condotrack_backend_production_cache`,
`condotrack_backend_production_queue` y `condotrack_backend_production_cable`.
`config/database.yml` toma host, puerto, usuario y password de `DATABASE_URL` para las cuatro
y descarta el nombre de base que traiga la URL. El contenedor las crea al arrancar
(`bin/rails db:prepare`), asi que el usuario de la URL necesita permiso `CREATEDB` (o hay que
crearlas a mano antes del primer deploy). El PostgreSQL debe ser alcanzable desde la red
Docker `course-net`, por ejemplo un contenedor `postgres:16-alpine` conectado a esa red:

```bash
docker run -d --name condotrack-prod-db --network course-net --restart unless-stopped \
  -e POSTGRES_USER=condotrack -e POSTGRES_PASSWORD=<password> \
  -v condotrack-prod-db:/var/lib/postgresql/data postgres:16-alpine
# credencial: postgres://condotrack:<password>@condotrack-prod-db:5432
```

## Producción

URL: <https://apicondotrack.frubilarz.cl> · Health check: <https://apicondotrack.frubilarz.cl/health>

## Credenciales de prueba

No hay usuarios precargados — la API permite registro abierto. Para probarla:

```bash
curl -X POST https://apicondotrack.frubilarz.cl/signup \
  -H "Content-Type: application/json" \
  -d '{"email":"tuemail@ejemplo.cl","password":"password123","nombre":"Tu Nombre"}'
```

Devuelve `{ token, user }`; usa ese `token` como `Authorization: Bearer <token>` en el
resto de los endpoints.