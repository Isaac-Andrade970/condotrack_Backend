# Datos de ejemplo para desarrollo y para que el docente pueda probar la app.
# Es idempotente: se puede ejecutar varias veces con `bin/rails db:seed`.
#
# Usuarios de prueba (solo demo, no usar estas claves en un entorno real):
#   demo@condotrack.cl   / password123
#   vecino@condotrack.cl / password123

demo = User.find_or_create_by!(email: "demo@condotrack.cl") do |u|
  u.nombre = "Usuario Demo"
  u.password = "password123"
end

vecino = User.find_or_create_by!(email: "vecino@condotrack.cl") do |u|
  u.nombre = "Vecino Demo"
  u.password = "password123"
end

categorias = {
  "Ascensores" => "Fallas o detenciones de ascensores",
  "Filtraciones" => "Filtraciones de agua en muros, techos o pasillos",
  "Luminarias" => "Luminarias quemadas o sin funcionar",
  "Ruidos molestos" => "Ruidos fuera de horario permitido",
  "Áreas comunes" => "Daños en áreas comunes del edificio"
}.map do |nombre, descripcion|
  Categoria.find_or_create_by!(nombre: nombre) { |c| c.descripcion = descripcion }
end.index_by(&:nombre)

reportes = [
  { titulo: "Ascensor torre B detenido", torre_unidad: "B-3", estado: "en_progreso",
    categoria: "Ascensores", usuario: demo },
  { titulo: "Filtración en pasillo piso 4", torre_unidad: "A-4", estado: "pendiente",
    categoria: "Filtraciones", usuario: vecino },
  { titulo: "Luminaria quemada en estacionamiento", torre_unidad: "Subterráneo -2", estado: "resuelto",
    categoria: "Luminarias", usuario: demo }
].map do |datos|
  Reporte.find_or_create_by!(titulo: datos[:titulo]) do |r|
    r.torre_unidad = datos[:torre_unidad]
    r.estado = datos[:estado]
    r.categoria = categorias.fetch(datos[:categoria])
    r.usuario = datos[:usuario]
  end
end

Comentario.find_or_create_by!(reporte: reportes[0], contenido: "Ya llamamos al técnico de mantención.") do |c|
  c.usuario = vecino
end
Comentario.find_or_create_by!(reporte: reportes[1], contenido: "Gracias por avisar, lo revisamos hoy.") do |c|
  c.usuario = demo
end
