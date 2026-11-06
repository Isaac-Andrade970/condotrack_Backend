class User < ApplicationRecord
  ROLES = %w[residente administrador].freeze

  has_secure_password

  has_many :reportes, foreign_key: :usuario_id, dependent: :destroy
  has_many :comentarios, foreign_key: :usuario_id, dependent: :destroy

  validates :email, presence: true, uniqueness: true,
    format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :nombre, presence: true
  validates :rol, inclusion: { in: ROLES }
  validates :password, length: { minimum: 6 }, if: -> { password.present? || new_record? }

  def administrador?
    rol == "administrador"
  end
end
