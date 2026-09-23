# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_09_21_000001) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "categorias", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "descripcion"
    t.string "nombre", null: false
    t.datetime "updated_at", null: false
    t.index [ "nombre" ], name: "index_categorias_on_nombre", unique: true
  end

  create_table "comentarios", force: :cascade do |t|
    t.text "contenido", null: false
    t.datetime "created_at", null: false
    t.bigint "reporte_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "usuario_id", null: false
    t.index [ "reporte_id" ], name: "index_comentarios_on_reporte_id"
    t.index [ "usuario_id" ], name: "index_comentarios_on_usuario_id"
  end

  create_table "reportes", force: :cascade do |t|
    t.bigint "categoria_id", null: false
    t.datetime "created_at", null: false
    t.text "descripcion"
    t.string "estado", default: "pendiente", null: false
    t.string "titulo", null: false
    t.string "torre_unidad"
    t.datetime "updated_at", null: false
    t.bigint "usuario_id", null: false
    t.index [ "categoria_id" ], name: "index_reportes_on_categoria_id"
    t.index [ "usuario_id" ], name: "index_reportes_on_usuario_id"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email", null: false
    t.string "nombre", null: false
    t.string "password_digest", null: false
    t.datetime "updated_at", null: false
    t.index [ "email" ], name: "index_users_on_email", unique: true
  end

  add_foreign_key "comentarios", "reportes"
  add_foreign_key "comentarios", "users", column: "usuario_id"
  add_foreign_key "reportes", "categorias"
  add_foreign_key "reportes", "users", column: "usuario_id"
end
