require "test_helper"

class ModelosTest < ActiveSupport::TestCase
  test "User exige email único, formato válido, nombre y contraseña mínima" do
    crear_usuario(email: "dup@test.cl")

    assert_not User.new(email: "dup@test.cl", nombre: "X", password: "password123").valid?, "email duplicado"
    assert_not User.new(email: "no-es-email", nombre: "X", password: "password123").valid?, "formato de email"
    assert_not User.new(email: "a@test.cl", nombre: "", password: "password123").valid?, "nombre vacío"
    assert_not User.new(email: "b@test.cl", nombre: "X", password: "123").valid?, "contraseña corta"
  end

  test "User guarda la contraseña con hash (no en texto plano)" do
    usuario = crear_usuario(password: "password123")

    assert_not_equal "password123", usuario.password_digest
    assert usuario.authenticate("password123")
    assert_not usuario.authenticate("otra-clave")
  end

  test "Categoria exige nombre único" do
    crear_categoria(nombre: "Ascensores")

    assert_not Categoria.new(nombre: "Ascensores").valid?
    assert_not Categoria.new(nombre: "").valid?
  end

  test "Reporte solo acepta los estados definidos" do
    usuario = crear_usuario
    reporte = crear_reporte(usuario: usuario)

    assert_equal "pendiente", reporte.estado, "estado por defecto"
    %w[pendiente en_progreso resuelto].each do |estado|
      reporte.estado = estado
      assert reporte.valid?, "#{estado} debería ser válido"
    end

    reporte.estado = "inventado"
    assert_not reporte.valid?
  end

  test "la base de datos también rechaza estados inválidos (check constraint)" do
    reporte = crear_reporte(usuario: crear_usuario)

    assert_raises(ActiveRecord::StatementInvalid) do
      reporte.update_column(:estado, "inventado")
    end
  end

  test "Categoria con reportes no se puede eliminar" do
    categoria = crear_categoria
    crear_reporte(usuario: crear_usuario, categoria: categoria)

    assert_not categoria.destroy
    assert Categoria.exists?(categoria.id)
  end

  test "Comentario exige contenido y expone el nombre del autor" do
    autor = crear_usuario(nombre: "Alexis")
    reporte = crear_reporte(usuario: autor)

    assert_not Comentario.new(reporte: reporte, usuario: autor, contenido: "").valid?

    json = crear_comentario(reporte: reporte, usuario: autor).as_json_with_author
    assert_equal "Alexis", json["usuario_nombre"]
    assert_not json.key?("password_digest")
  end

  test "al borrar un usuario se borran sus reportes y comentarios" do
    usuario = crear_usuario
    otro = crear_usuario
    reporte_ajeno = crear_reporte(usuario: otro)
    crear_comentario(reporte: reporte_ajeno, usuario: usuario)
    crear_reporte(usuario: usuario)

    assert_nothing_raised { usuario.destroy }
    assert_equal 0, Comentario.where(usuario_id: usuario.id).count
    assert_equal 0, Reporte.where(usuario_id: usuario.id).count
  end
end
