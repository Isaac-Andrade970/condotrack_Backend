class Reporte < ApplicationRecord
  ESTADOS = %w[pendiente en_progreso resuelto].freeze

  belongs_to :categoria
  belongs_to :usuario, class_name: "User", foreign_key: :usuario_id

  has_many :comentarios, dependent: :destroy

  validates :titulo, presence: true
  validates :estado, presence: true, inclusion: { in: ESTADOS }
end
