class Comentario < ApplicationRecord
  belongs_to :reporte
  belongs_to :usuario, class_name: "User", foreign_key: :usuario_id

  validates :contenido, presence: true

  # Serialización pública: atributos del comentario + nombre del autor (nunca
  # se expone nada más del usuario, ej. email o password_digest).
  def as_json_with_author
    as_json.merge("usuario_nombre" => usuario.nombre)
  end
end
