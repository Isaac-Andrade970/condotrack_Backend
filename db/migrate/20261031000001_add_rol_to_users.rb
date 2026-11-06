class AddRolToUsers < ActiveRecord::Migration[8.1]
  def change
    # Los usuarios existentes quedan como "residente" gracias al default.
    add_column :users, :rol, :string, null: false, default: "residente"

    add_check_constraint :users,
      "rol IN ('residente', 'administrador')",
      name: "users_rol_valido"
  end
end
