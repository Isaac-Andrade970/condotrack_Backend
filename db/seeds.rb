# Datos de ejemplo para desarrollo y para que el docente pueda probar la app.
# Es idempotente: se puede ejecutar varias veces con `bin/rails db:seed`.
#
# Usuarios de prueba (solo demo, no usar estas claves en un entorno real):
#   admin@condotrack.cl  / password123  (rol administrador)
#   demo@condotrack.cl   / password123  (rol residente)
#   vecino@condotrack.cl / password123  (rol residente)
#
# En producción NO se crean claves conocidas: solo el administrador, con la clave
# que se pase en SEED_ADMIN_PASSWORD (y SEED_ADMIN_EMAIL, opcional):
#   SEED_ADMIN_PASSWORD=... bin/rails db:seed

# Crea el usuario si no existe y siempre deja el rol indicado (así volver a correr
# los seeds corrige un rol cambiado a mano). La clave solo se fija al crearlo.
def sembrar_usuario(email:, nombre:, rol:, password:)
  User.find_or_initialize_by(email: email).tap do |u|
    u.nombre = nombre
    u.rol = rol
    u.password = password if u.new_record?
    u.save!
  end
end

if Rails.env.production?
  password = ENV["SEED_ADMIN_PASSWORD"]
  abort "En producción defina SEED_ADMIN_PASSWORD para crear el administrador." if password.blank?

  sembrar_usuario(email: ENV.fetch("SEED_ADMIN_EMAIL", "admin@condotrack.cl"),
    nombre: "Administrador", rol: "administrador", password: password)
  puts "Administrador listo. No se cargaron datos de ejemplo en producción."
  return
end

admin = sembrar_usuario(email: "admin@condotrack.cl", nombre: "Administrador Demo",
  rol: "administrador", password: "password123")
demo = sembrar_usuario(email: "demo@condotrack.cl", nombre: "Usuario Demo",
  rol: "residente", password: "password123")
vecino = sembrar_usuario(email: "vecino@condotrack.cl", nombre: "Vecino Demo",
  rol: "residente", password: "password123")

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
  c.usuario = admin
end
