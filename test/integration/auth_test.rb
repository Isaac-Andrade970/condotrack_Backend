require "test_helper"

class AuthTest < ActionDispatch::IntegrationTest
  test "POST /signup crea el usuario y devuelve token (201) sin exponer password_digest" do
    post "/signup", params: { email: "nuevo@test.cl", password: "password123", nombre: "Nuevo" }, as: :json

    assert_response :created
    assert response.parsed_body["token"].present?
    assert_equal "nuevo@test.cl", response.parsed_body.dig("user", "email")
    assert_not response.parsed_body["user"].key?("password_digest")
  end

  test "POST /signup con datos inválidos responde 422 con la lista de errores" do
    post "/signup", params: { email: "malo", password: "123", nombre: "" }, as: :json

    assert_response :unprocessable_entity
    assert response.parsed_body["errors"].is_a?(Array)
    assert_not_empty response.parsed_body["errors"]
  end

  test "POST /login con credenciales válidas devuelve token (200)" do
    crear_usuario(email: "ok@test.cl", password: "password123")

    post "/login", params: { email: "ok@test.cl", password: "password123" }, as: :json

    assert_response :ok
    assert response.parsed_body["token"].present?
  end

  test "POST /login con contraseña incorrecta responde 401" do
    crear_usuario(email: "ok@test.cl", password: "password123")

    post "/login", params: { email: "ok@test.cl", password: "incorrecta" }, as: :json

    assert_response :unauthorized
    assert_equal "Credenciales inválidas", response.parsed_body["error"]
  end

  test "POST /login con un email que no existe responde 401" do
    post "/login", params: { email: "nadie@test.cl", password: "password123" }, as: :json

    assert_response :unauthorized
  end

  test "GET /me sin token responde 401 y con token devuelve el usuario" do
    get "/me"
    assert_response :unauthorized

    usuario = crear_usuario(nombre: "Isaac")
    get "/me", headers: auth_headers(usuario)

    assert_response :ok
    assert_equal "Isaac", response.parsed_body["nombre"]
  end

  test "un token expirado o manipulado responde 401" do
    usuario = crear_usuario
    expirado = JsonWebToken.encode({ user_id: usuario.id }, 1.hour.ago)

    get "/me", headers: { "Authorization" => "Bearer #{expirado}" }
    assert_response :unauthorized

    get "/me", headers: { "Authorization" => "Bearer token.manipulado.xyz" }
    assert_response :unauthorized
  end

  test "los recursos protegidos responden 401 sin token" do
    get "/reportes"
    assert_response :unauthorized

    get "/categorias"
    assert_response :unauthorized
  end
end
