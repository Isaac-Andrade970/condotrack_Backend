require "test_helper"

class RecursosTest < ActionDispatch::IntegrationTest
  setup do
    @autor = crear_usuario(nombre: "Autor")
    @otro = crear_usuario(nombre: "Otro")
    @categoria = crear_categoria
    @reporte = crear_reporte(usuario: @autor, categoria: @categoria)
  end

  # --- Categorías -------------------------------------------------------

  test "DELETE /categorias/:id con reportes asociados responde 409 y no la borra" do
    delete "/categorias/#{@categoria.id}", headers: auth_headers(@autor)

    assert_response :conflict
    assert_match(/reportes asociados/, response.parsed_body["errors"].first)
    assert Categoria.exists?(@categoria.id)
  end

  test "DELETE /categorias/:id sin reportes responde 204" do
    libre = crear_categoria

    delete "/categorias/#{libre.id}", headers: auth_headers(@autor)

    assert_response :no_content
    assert_not Categoria.exists?(libre.id)
  end

  test "POST /categorias con nombre duplicado responde 422" do
    post "/categorias", params: { nombre: @categoria.nombre }, headers: auth_headers(@autor), as: :json

    assert_response :unprocessable_entity
  end

  # --- Reportes: autorización por dueño ---------------------------------

  test "POST /reportes asigna el dueño desde el token (201)" do
    post "/reportes", params: { titulo: "Nuevo", categoria_id: @categoria.id }, headers: auth_headers(@otro), as: :json

    assert_response :created
    assert_equal @otro.id, response.parsed_body["usuario_id"]
  end

  test "PATCH /reportes/:id de otro usuario responde 403 y no cambia nada" do
    patch "/reportes/#{@reporte.id}", params: { titulo: "Hackeado" }, headers: auth_headers(@otro), as: :json

    assert_response :forbidden
    assert_equal "Reporte de prueba", @reporte.reload.titulo
  end

  test "DELETE /reportes/:id de otro usuario responde 403" do
    delete "/reportes/#{@reporte.id}", headers: auth_headers(@otro)

    assert_response :forbidden
    assert Reporte.exists?(@reporte.id)
  end

  test "el dueño sí puede editar y eliminar su reporte" do
    patch "/reportes/#{@reporte.id}", params: { estado: "resuelto" }, headers: auth_headers(@autor), as: :json
    assert_response :ok
    assert_equal "resuelto", @reporte.reload.estado

    delete "/reportes/#{@reporte.id}", headers: auth_headers(@autor)
    assert_response :no_content
  end

  test "PATCH /reportes/:id con estado inválido responde 422" do
    patch "/reportes/#{@reporte.id}", params: { estado: "inventado" }, headers: auth_headers(@autor), as: :json

    assert_response :unprocessable_entity
  end

  test "GET /reportes/:id inexistente responde 404 en JSON" do
    get "/reportes/999999", headers: auth_headers(@autor)

    assert_response :not_found
    assert_match(/Reporte/, response.parsed_body["error"])
  end

  # --- Reportes: orden y paginación -------------------------------------

  test "GET /reportes sin parámetros devuelve todos ordenados" do
    segundo = crear_reporte(usuario: @autor, titulo: "Segundo")

    get "/reportes", headers: auth_headers(@autor)

    assert_response :ok
    assert_equal [ @reporte.id, segundo.id ], response.parsed_body.map { |r| r["id"] }
    assert_nil response.headers["X-Total-Count"]
  end

  test "GET /reportes con per_page pagina y expone X-Total-Count" do
    3.times { |i| crear_reporte(usuario: @autor, titulo: "Extra #{i}") }

    get "/reportes", params: { page: 2, per_page: 2 }, headers: auth_headers(@autor)

    assert_response :ok
    assert_equal 2, response.parsed_body.size
    assert_equal "4", response.headers["X-Total-Count"]
  end

  # --- Comentarios ------------------------------------------------------

  test "GET comentarios incluye usuario_nombre sin consultas N+1" do
    3.times { |i| crear_comentario(reporte: @reporte, usuario: crear_usuario(nombre: "Autor #{i}")) }

    consultas = 0
    contador = ->(*, payload) { consultas += 1 unless payload[:name] == "SCHEMA" || payload[:cached] }
    ActiveSupport::Notifications.subscribed(contador, "sql.active_record") do
      get "/reportes/#{@reporte.id}/comentarios", headers: auth_headers(@autor)
    end

    assert_response :ok
    assert_equal [ "Autor 0", "Autor 1", "Autor 2" ], response.parsed_body.map { |c| c["usuario_nombre"] }
    # auth (1) + reporte (1) + comentarios (1) + usuarios (1): no crece con la cantidad
    assert_operator consultas, :<=, 5
  end

  test "POST comentario guarda el autor desde el token (201)" do
    post "/reportes/#{@reporte.id}/comentarios", params: { contenido: "Hola" }, headers: auth_headers(@otro), as: :json

    assert_response :created
    assert_equal "Otro", response.parsed_body["usuario_nombre"]
  end

  test "PATCH y DELETE de un comentario ajeno responden 403" do
    comentario = crear_comentario(reporte: @reporte, usuario: @autor)

    patch "/reportes/#{@reporte.id}/comentarios/#{comentario.id}", params: { contenido: "X" },
      headers: auth_headers(@otro), as: :json
    assert_response :forbidden

    delete "/reportes/#{@reporte.id}/comentarios/#{comentario.id}", headers: auth_headers(@otro)
    assert_response :forbidden
    assert Comentario.exists?(comentario.id)
  end

  test "el autor edita y elimina su comentario" do
    comentario = crear_comentario(reporte: @reporte, usuario: @autor)

    patch "/reportes/#{@reporte.id}/comentarios/#{comentario.id}", params: { contenido: "Editado" },
      headers: auth_headers(@autor), as: :json
    assert_response :ok
    assert_equal "Editado", response.parsed_body["contenido"]

    delete "/reportes/#{@reporte.id}/comentarios/#{comentario.id}", headers: auth_headers(@autor)
    assert_response :no_content
  end

  test "comentario vacío responde 422 y comentario inexistente 404" do
    post "/reportes/#{@reporte.id}/comentarios", params: { contenido: "" }, headers: auth_headers(@autor), as: :json
    assert_response :unprocessable_entity

    patch "/reportes/#{@reporte.id}/comentarios/999999", params: { contenido: "X" },
      headers: auth_headers(@autor), as: :json
    assert_response :not_found
  end
end
