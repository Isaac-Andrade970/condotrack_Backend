require "test_helper"

# Los seeds dan un usuario por rol para probar la API, la web y la app móvil.
class SeedsTest < ActiveSupport::TestCase
  setup do
    # Los seeds imprimen poco, pero no queremos ruido en la salida de los tests.
    @salida = [ $stdout, $stderr ]
    $stdout = $stderr = StringIO.new
  end

  teardown { $stdout, $stderr = @salida }

  test "crea un administrador y dos residentes" do
    Rails.application.load_seed

    assert_equal "administrador", User.find_by!(email: "admin@condotrack.cl").rol
    assert_equal "residente", User.find_by!(email: "demo@condotrack.cl").rol
    assert_equal "residente", User.find_by!(email: "vecino@condotrack.cl").rol
  end

  test "los usuarios de los seeds pueden iniciar sesión" do
    Rails.application.load_seed

    %w[admin demo vecino].each do |nombre|
      assert User.find_by!(email: "#{nombre}@condotrack.cl").authenticate("password123")
    end
  end

  test "es idempotente y corrige un rol cambiado a mano" do
    Rails.application.load_seed
    User.find_by!(email: "admin@condotrack.cl").update!(rol: "residente")

    assert_no_difference [ "User.count", "Categoria.count", "Reporte.count", "Comentario.count" ] do
      Rails.application.load_seed
    end
    assert_equal "administrador", User.find_by!(email: "admin@condotrack.cl").rol
  end

  # En producción los seeds no deben dejar claves conocidas ni datos de ejemplo.
  test "en producción exige SEED_ADMIN_PASSWORD" do
    en_produccion(password: nil) do
      assert_raises(SystemExit) { Rails.application.load_seed }
    end
    assert_equal 0, User.count
  end

  test "en producción crea solo el administrador con la clave indicada" do
    en_produccion(password: "clave-secreta-123") do
      Rails.application.load_seed
    end

    assert_equal [ "admin@condotrack.cl" ], User.pluck(:email)
    admin = User.first
    assert admin.administrador?
    assert admin.authenticate("clave-secreta-123")
    assert_not admin.authenticate("password123")
    assert_equal 0, Reporte.count
    assert_equal 0, Categoria.count
  end

  private

  def en_produccion(password:)
    entorno = Rails.env
    clave = ENV["SEED_ADMIN_PASSWORD"]
    Rails.env = "production"
    password ? ENV["SEED_ADMIN_PASSWORD"] = password : ENV.delete("SEED_ADMIN_PASSWORD")
    yield
  ensure
    Rails.env = entorno
    clave ? ENV["SEED_ADMIN_PASSWORD"] = clave : ENV.delete("SEED_ADMIN_PASSWORD")
  end
end
