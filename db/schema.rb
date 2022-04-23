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

ActiveRecord::Schema[7.0].define(version: 2022_02_08_200104) do
  create_table "authors", force: :cascade do |t|
    t.string "name"
    t.string "name_romaji"
    t.string "name_kana"
    t.string "name_kakasi"
    t.text "info"
    t.text "aliases"
    t.text "links"
    t.integer "doujinshi_org_id"
    t.string "doujinshi_org_url", default: "", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "authors_circles", id: false, force: :cascade do |t|
    t.integer "author_id", null: false
    t.integer "circle_id", null: false
    t.datetime "created_at"
    t.index ["author_id", "circle_id"], name: "index_authors_circles_on_author_id_and_circle_id", unique: true
    t.index ["author_id"], name: "index_authors_circles_on_author_id"
    t.index ["circle_id"], name: "index_authors_circles_on_circle_id"
  end

  create_table "authors_doujinshi", id: false, force: :cascade do |t|
    t.integer "author_id", null: false
    t.integer "doujin_id", null: false
    t.datetime "created_at"
    t.index ["author_id", "doujin_id"], name: "index_authors_doujinshi_on_author_id_and_doujin_id", unique: true
    t.index ["author_id"], name: "index_authors_doujinshi_on_author_id"
    t.index ["doujin_id"], name: "index_authors_doujinshi_on_doujin_id"
  end

  create_table "authors_themes", id: false, force: :cascade do |t|
    t.integer "author_id", null: false
    t.integer "theme_id", null: false
    t.datetime "created_at"
    t.index ["author_id", "theme_id"], name: "index_authors_themes_on_author_id_and_theme_id", unique: true
    t.index ["author_id"], name: "index_authors_themes_on_author_id"
    t.index ["theme_id"], name: "index_authors_themes_on_theme_id"
  end

  create_table "circles", force: :cascade do |t|
    t.string "name"
    t.string "name_romaji"
    t.string "name_kana"
    t.string "name_kakasi"
    t.text "info"
    t.text "aliases"
    t.text "links"
    t.integer "doujinshi_org_id"
    t.string "doujinshi_org_url", default: "", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "circles_doujinshi", id: false, force: :cascade do |t|
    t.integer "circle_id", null: false
    t.integer "doujin_id", null: false
    t.datetime "created_at"
    t.index ["circle_id", "doujin_id"], name: "index_circles_doujinshi_on_circle_id_and_doujin_id", unique: true
    t.index ["circle_id"], name: "index_circles_doujinshi_on_circle_id"
    t.index ["doujin_id"], name: "index_circles_doujinshi_on_doujin_id"
  end

  create_table "circles_themes", id: false, force: :cascade do |t|
    t.integer "circle_id", null: false
    t.integer "theme_id", null: false
    t.datetime "created_at"
    t.index ["circle_id", "theme_id"], name: "index_circles_themes_on_circle_id_and_theme_id", unique: true
    t.index ["circle_id"], name: "index_circles_themes_on_circle_id"
    t.index ["theme_id"], name: "index_circles_themes_on_theme_id"
  end

  create_table "doujinshi", force: :cascade do |t|
    t.string "name"
    t.string "name_romaji"
    t.string "name_kakasi"
    t.integer "size"
    t.string "checksum"
    t.integer "num_images"
    t.integer "num_files"
    t.integer "score"
    t.text "name_orig"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "category"
    t.text "file_folder"
    t.text "file_name"
  end

  create_table "settings", force: :cascade do |t|
    t.string "key", null: false
    t.string "value", null: false
    t.string "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "themes", force: :cascade do |t|
    t.string "name"
    t.string "name_romaji"
    t.string "name_kana"
    t.string "name_kakasi"
    t.text "info"
    t.text "aliases"
    t.text "links"
    t.integer "parent_id"
    t.integer "doujinshi_org_id"
    t.string "doujinshi_org_url", default: "", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_foreign_key "authors_circles", "authors"
  add_foreign_key "authors_circles", "circles"
  add_foreign_key "authors_doujinshi", "authors"
  add_foreign_key "authors_doujinshi", "doujinshi"
  add_foreign_key "authors_themes", "authors"
  add_foreign_key "authors_themes", "themes"
  add_foreign_key "circles_doujinshi", "circles"
  add_foreign_key "circles_doujinshi", "doujinshi"
  add_foreign_key "circles_themes", "circles"
  add_foreign_key "circles_themes", "themes"
end
