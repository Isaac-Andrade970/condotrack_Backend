require "test_helper"

# Autorización por rol (residente / administrador) y por dueño.
# 401 = sin sesión válida; 403 = autenticado pero sin permiso.
class AutorizacionTest < ActionDispatch::IntegrationTest
  setup do
    @residente = crear_usuario(nombre: "Residente")
    @otro = crear_usuario(nombre: "Otro residente")
    @admin = crear_usuario(nombre: "Admin", rol: "administrador")
    @categoria = crear_categoria
    @reporte = crear_reporte(usuario: @residente, categoria: @categoria)
  end

  # --- Categorías: acciones solo para administrador ----------------------

  test "sin token no se puede crear una categoría (401)" do
    post "/categorias", params: { nombre: "Nueva" }, as: :json

    assert_response :unauthorized
  end

  test "un residente puede listar las categorías" do
    get "/categorias", headers: auth_headers(@residente)

    assert_response :ok
  end

  test "un residente no puede crear una categoría (403)" do
    assert_no_difference "Categoria.count" do
      post "/categorias", params: { nombre: "Nueva" }, headers: auth_headers(@residente), as: :json
    end

    assert_response :forbidden
    assert_match(/administradores/, response.parsed_body["error"])
  end

  test "un residente no puede editar una categoría (403)" do
    patch "/categorias/#{@categoria.id}", params: { nombre: "Hackeada" }, headers: auth_headers(@residente), as: :json

    assert_response :forbidden
    assert_not_equal "Hackeada", @categoria.reload.nombre
  end

  test "un residente no puede eliminar una categoría (403)" do
    libre = crear_categoria

    delete "/categorias/#{libre.id}", headers: auth_headers(@residente)

    assert_response :forbidden
    assert Categoria.exists?(libre.id)
  end

  test "un administrador crea, edita y elimina categorías" do
    post "/categorias", params: { nombre: "Ascensores" }, headers: auth_headers(@admin), as: :json
    assert_response :created
    id = response.parsed_body["id"]

    patch "/categorias/#{id}", params: { nombre: "Ascensores y rampas" }, headers: auth_headers(@admin), as: :json
    assert_response :ok
    assert_equal "Ascensores y rampas", Categoria.find(id).nombre

    delete "/categorias/#{id}", headers: auth_headers(@admin)
    assert_response :no_content
    assert_not Categoria.exists?(id)
  end

  # --- Reportes: estado (administrador) y contenido (dueño) --------------

  test "un administrador cambia el estado de un reporte ajeno" do
    patch "/reportes/#{@reporte.id}", params: { estado: "en_progreso" }, headers: auth_headers(@admin), as: :json

    assert_response :ok
    assert_equal "en_progreso", @reporte.reload.estado
  end

  test "un administrador no puede editar el contenido de un reporte ajeno (403)" do
    patch "/reportes/#{@reporte.id}", params: { titulo: "Censurado", estado: "resuelto" }, headers: auth_headers(@admin), as: :json

    assert_response :forbidden
    assert_equal "Reporte de prueba", @reporte.reload.titulo
    assert_equal "pendiente", @reporte.estado
  end

  test "un residente no puede cambiar el estado del reporte de otro (403)" do
    patch "/reportes/#{@reporte.id}", params: { estado: "resuelto" }, headers: auth_headers(@otro), as: :json

    assert_response :forbidden
    assert_equal "pendiente", @reporte.reload.estado
  end

  test "un administrador no puede eliminar el reporte de un residente (403)" do
    assert_no_difference "Reporte.count" do
      delete "/reportes/#{@reporte.id}", headers: auth_headers(@admin)
    end

    assert_response :forbidden
  end

  test "el dueño sigue editando todo su reporte aunque sea residente" do
    patch "/reportes/#{@reporte.id}", params: { titulo: "Editado", estado: "resuelto" }, headers: auth_headers(@residente), as: :json

    assert_response :ok
    assert_equal "Editado", @reporte.reload.titulo
  end

  # --- Comentarios: solo el autor, también frente al administrador -------

  test "un administrador no puede editar ni borrar un comentario ajeno (403)" do
    comentario = crear_comentario(reporte: @reporte, usuario: @residente)

    patch "/reportes/#{@reporte.id}/comentarios/#{comentario.id}", params: { contenido: "x" }, headers: auth_headers(@admin), as: :json
    assert_response :forbidden

    delete "/reportes/#{@reporte.id}/comentarios/#{comentario.id}", headers: auth_headers(@admin)
    assert_response :forbidden
    assert Comentario.exists?(comentario.id)
  end
end
