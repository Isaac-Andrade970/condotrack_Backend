# Changelog

## Correcciones del feedback de la Tarea 1 — backend

Rama: `fix/backend-feedback-tarea1` · Responde a los puntos de la sección B del feedback del docente.

### Corregido (fix)

| # | Cambio | Dónde |
|---|---|---|
| 1 | `DELETE /categorias/:id` respondía `204` aunque `restrict_with_error` impidiera borrar. Ahora responde `409` con el motivo y la categoría no se borra. | `categorias_controller.rb` |
| 2 | **Autorización por dueño:** solo el autor puede editar o eliminar un reporte o un comentario. Otro usuario autenticado recibe `403`. | `application_controller.rb` (`authorize_owner!`), `reportes_controller.rb`, `comentarios_controller.rb` |
| 3 | **Manejo centralizado de errores:** `rescue_from` para `RecordNotFound` (404) y JSON mal formado (400). Se eliminaron los `rescue` repetidos en cada controller. | `application_controller.rb` |
| 4 | Rutas inexistentes responden `404` con cuerpo JSON (antes: cuerpo vacío), sin requerir token. | `errors_controller.rb`, `routes.rb` |
| 5 | `User` declara `has_many :comentarios, dependent: :destroy`: borrar un usuario con comentarios ya no rompe por la clave foránea. | `user.rb` |
| 6 | `estado` de `reportes` tiene un **check constraint** en PostgreSQL (`pendiente`, `en_progreso`, `resuelto`), además de la validación del modelo. | migración `20261019000001`, `schema.rb` |
| 7 | **CORS restringido** (antes `origins "*"`) a Vercel, `condotrack.frubilarz.cl` y `localhost:5173`; configurable con `CORS_ORIGINS`. Se eliminó el comentario con el ejemplo `reportaya.vercel.app`. | `cors.rb` |

### Agregado (feature)

| # | Cambio | Dónde |
|---|---|---|
| 8 | Los comentarios incluyen `usuario_nombre`, cargado con `includes(:usuario)` (sin N+1). Nunca se expone email ni `password_digest`. | `comentarios_controller.rb`, `comentario.rb` |
| 9 | Listados con orden determinista y **paginación opcional** (`?page`, `?per_page`, header `X-Total-Count`). Sin parámetros devuelven todo, así que el frontend actual sigue funcionando. | `application_controller.rb` (`paginate`) |
| 10 | **Seeds útiles** e idempotentes: 2 usuarios demo, 5 categorías, 3 reportes, 2 comentarios. | `db/seeds.rb` |

### Tests (test)

37 tests propios con 95 aserciones (antes solo existía el test de health, del docente):

- `test/models/modelos_test.rb`: validaciones, hash de contraseña, check constraint, `restrict_with_error`, borrado en cascada.
- `test/integration/auth_test.rb`: signup, login válido e inválido, `/me`, token expirado o manipulado, `401`.
- `test/integration/recursos_test.rb`: `403`/`409`/`422`/`404`, paginación, `usuario_nombre` y N+1.
- `test/integration/errores_test.rb`: `404` JSON, JSON mal formado, health.

Verificación de que los tests detectan los errores: con los 3 controllers originales fallan 7 tests; con el código nuevo pasan los 37.
Comandos: `bin/rails test`, `bin/rubocop` (0 offenses) y `bin/brakeman` (0 warnings).

### Documentación (docs)

- README: reglas de la API, sección de variables de entorno, seeds y endpoint `PATCH` de comentarios (faltaba).

### Notas y límites

- **`ParameterMissing`:** los controllers usan `params.permit` (no `params.require`), así que esa excepción no se produce; lo que sí se producía era JSON mal formado, y ese caso ya se maneja.
- **Estados de reporte:** como ahora solo edita el autor, "cambiar el estado" queda para el dueño hasta que existan roles (Tarea 2).
- **Seeds en producción:** el deploy hace `db:prepare`, que no ejecuta seeds en una base ya creada. Habría que correr `bin/rails db:seed` a mano en producción si se quieren los usuarios demo.
- **CORS:** si el frontend cambia de dominio, hay que agregarlo en `CORS_ORIGINS` o `cors.rb`.
- **Migración nueva:** al desplegar, `db:prepare` agrega el check constraint (los datos existentes ya cumplen los 3 estados).

### Pendiente (no incluido en esta rama)

- Swagger/OpenAPI y rate limiting en login (extras de la sección B).
- Todos los cambios del frontend (sección C), por ejemplo mostrar `usuario_nombre`, manejar el `401` y manejar el `403`.
