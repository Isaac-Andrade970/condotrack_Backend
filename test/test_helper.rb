ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # Helpers de datos: los tests crean sus propios registros (sin fixtures).
    def crear_usuario(email: "user#{SecureRandom.hex(3)}@test.cl", nombre: "Usuario Test", password: "password123")
      User.create!(email: email, nombre: nombre, password: password)
    end

    def crear_categoria(nombre: "Categoria #{SecureRandom.hex(3)}")
      Categoria.create!(nombre: nombre)
    end

    def crear_reporte(usuario:, categoria: crear_categoria, titulo: "Reporte de prueba")
      Reporte.create!(titulo: titulo, usuario: usuario, categoria: categoria)
    end

    def crear_comentario(reporte:, usuario:, contenido: "Comentario de prueba")
      Comentario.create!(reporte: reporte, usuario: usuario, contenido: contenido)
    end
  end
end

class ActionDispatch::IntegrationTest
  # Headers con JWT válido para el usuario dado.
  def auth_headers(usuario)
    { "Authorization" => "Bearer #{JsonWebToken.encode(user_id: usuario.id)}" }
  end
end
