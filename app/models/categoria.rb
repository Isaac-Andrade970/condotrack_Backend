class Categoria < ApplicationRecord
  # El inflector de Rails trata "categoria" como ya-plural (regla latina
  # para palabras terminadas en "-ia", ej. "criteria"), así que sin esto
  # ActiveRecord buscaría una tabla llamada "categoria" en vez de "categorias".
  self.table_name = "categorias"

  has_many :reportes, dependent: :restrict_with_error

  validates :nombre, presence: true, uniqueness: true
end
