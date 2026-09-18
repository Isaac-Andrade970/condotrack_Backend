class CreateReportes < ActiveRecord::Migration[8.1]
  def change
    create_table :reportes do |t|
      t.string :titulo, null: false
      t.text :descripcion
      t.string :estado, null: false, default: "pendiente"
      t.string :torre_unidad
      t.references :categoria, null: false, foreign_key: { to_table: :categorias }
      t.references :usuario, null: false, foreign_key: { to_table: :users }

      t.timestamps
    end
  end
end
