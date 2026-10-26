require "test_helper"

class ErroresTest < ActionDispatch::IntegrationTest
  test "una ruta inexistente responde 404 con cuerpo JSON (sin autenticación)" do
    get "/esta-ruta-no-existe"

    assert_response :not_found
    assert_match(%r{/esta-ruta-no-existe}, response.parsed_body["error"])
  end

  test "un método no soportado en una ruta existente también responde 404 JSON" do
    put "/login"

    assert_response :not_found
    assert response.parsed_body["error"].present?
  end

  test "un JSON mal formado responde 400 en vez de reventar" do
    post "/login", params: "{esto no es json", headers: { "CONTENT_TYPE" => "application/json" }

    assert_response :bad_request
    assert_match(/JSON/, response.parsed_body["error"])
  end

  test "el health check sigue funcionando sin token" do
    get "/health"

    assert_response :ok
  end
end
