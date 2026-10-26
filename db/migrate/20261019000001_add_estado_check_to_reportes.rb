class AddEstadoCheckToReportes < ActiveRecord::Migration[8.1]
  def change
    add_check_constraint :reportes,
      "estado IN ('pendiente', 'en_progreso', 'resuelto')",
      name: "reportes_estado_valido"
  end
end
