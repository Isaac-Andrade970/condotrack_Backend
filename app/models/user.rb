class User < ApplicationRecord
  has_secure_password

  validates :email, presence: true, uniqueness: true,
    format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :nombre, presence: true
  validates :password, length: { minimum: 6 }, if: -> { password.present? || new_record? }
end
