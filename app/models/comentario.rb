class Comentario < ApplicationRecord
  belongs_to :reporte
  belongs_to :usuario, class_name: "User", foreign_key: :usuario_id

  validates :contenido, presence: true
end
