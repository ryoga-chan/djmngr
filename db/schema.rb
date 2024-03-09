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

ActiveRecord::Schema[7.1].define(version: 2024_02_01_164045) do
  create_table "authors", force: :cascade do |t|
    t.string "name", null: false
    t.string "name_romaji"
    t.string "name_kana"
    t.string "name_kakasi", null: false
    t.text "info"
    t.text "aliases"
    t.text "links"
    t.integer "doujinshi_org_id"
    t.string "doujinshi_org_url", default: "", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "favorite", default: false
    t.datetime "faved_at"
    t.integer "doujinshi_org_aka_id"
    t.string "notes"
    t.index ["doujinshi_org_aka_id"], name: "index_authors_on_doujinshi_org_aka_id"
    t.index ["doujinshi_org_id"], name: "index_authors_on_doujinshi_org_id"
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
    t.string "name", null: false
    t.string "name_romaji"
    t.string "name_kana"
    t.string "name_kakasi", null: false
    t.text "info"
    t.text "aliases"
    t.text "links"
    t.integer "doujinshi_org_id"
    t.string "doujinshi_org_url", default: "", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "favorite", default: false
    t.datetime "faved_at"
    t.integer "doujinshi_org_aka_id"
    t.string "notes"
    t.index ["doujinshi_org_aka_id"], name: "index_circles_on_doujinshi_org_aka_id"
    t.index ["doujinshi_org_id"], name: "index_circles_on_doujinshi_org_id"
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

  create_table "deleted_doujinshi", force: :cascade do |t|
    t.string "name", null: false
    t.string "name_kakasi", null: false
    t.string "alt_name"
    t.string "alt_name_kakasi"
    t.integer "size", null: false
    t.integer "num_images", null: false
    t.integer "num_files", null: false
    t.integer "doujin_id"
    t.datetime "created_at"
    t.integer "cover_phash"
  end

  create_table "doujinshi", force: :cascade do |t|
    t.string "name", null: false
    t.string "name_romaji"
    t.string "name_kakasi", null: false
    t.integer "size", null: false
    t.string "checksum", null: false
    t.integer "num_images", null: false
    t.integer "num_files", null: false
    t.integer "score"
    t.string "name_orig", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "category", null: false
    t.string "file_folder", null: false
    t.string "file_name", null: false
    t.datetime "scored_at"
    t.string "reading_direction", limit: 3, default: "r2l"
    t.integer "read_pages", default: 0
    t.string "language", limit: 3, default: "jpn"
    t.boolean "censored", default: true
    t.boolean "colorized", default: false
    t.string "notes"
    t.boolean "favorite", default: false
    t.datetime "faved_at"
    t.string "name_orig_kakasi", null: false
    t.integer "cover_phash"
    t.string "name_eng"
    t.string "media_type", default: "doujin"
    t.date "released_at"
  end

  create_table "doujinshi_shelves", force: :cascade do |t|
    t.integer "doujin_id", null: false
    t.integer "shelf_id", null: false
    t.integer "position"
    t.datetime "created_at"
    t.index ["doujin_id"], name: "index_doujinshi_shelves_on_doujin_id"
    t.index ["shelf_id"], name: "index_doujinshi_shelves_on_shelf_id"
  end

  create_table "processable_doujin_dupes", force: :cascade do |t|
    t.integer "pd_parent_id"
    t.integer "pd_child_id"
    t.integer "doujin_id"
    t.integer "likeness", null: false
    t.datetime "created_at"
    t.index ["doujin_id"], name: "index_processable_doujin_dupes_on_doujin_id"
    t.index ["pd_child_id"], name: "index_processable_doujin_dupes_on_pd_child_id"
    t.index ["pd_parent_id"], name: "index_processable_doujin_dupes_on_pd_parent_id"
  end

  create_table "processable_doujinshi", force: :cascade do |t|
    t.string "name", null: false
    t.string "name_kakasi", null: false
    t.integer "size", null: false
    t.datetime "created_at"
    t.datetime "mtime"
    t.integer "images"
    t.integer "cover_phash"
    t.string "notes"
  end

  create_table "settings", force: :cascade do |t|
    t.string "key", null: false
    t.string "value", null: false
    t.string "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "shelves", force: :cascade do |t|
    t.string "name"
    t.integer "num_images"
    t.datetime "created_at"
  end

  create_table "themes", force: :cascade do |t|
    t.string "name", null: false
    t.string "name_romaji"
    t.string "name_kana"
    t.string "name_kakasi", null: false
    t.text "info"
    t.text "aliases"
    t.text "links"
    t.integer "parent_id"
    t.integer "doujinshi_org_id"
    t.string "doujinshi_org_url", default: "", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "doujinshi_org_aka_id"
    t.string "notes"
    t.index ["doujinshi_org_aka_id"], name: "index_themes_on_doujinshi_org_aka_id"
    t.index ["doujinshi_org_id"], name: "index_themes_on_doujinshi_org_id"
  end

  create_table "versions", force: :cascade do |t|
    t.string "item_type", null: false
    t.bigint "item_id", null: false
    t.string "event", null: false
    t.string "whodunnit"
    t.text "object_changes"
    t.datetime "created_at"
    t.index ["item_type", "item_id"], name: "index_versions_on_item_type_and_item_id"
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
  add_foreign_key "doujinshi_shelves", "doujinshi"
  add_foreign_key "doujinshi_shelves", "shelves"
  add_foreign_key "processable_doujin_dupes", "doujinshi"
  add_foreign_key "processable_doujin_dupes", "processable_doujinshi", column: "pd_child_id"
  add_foreign_key "processable_doujin_dupes", "processable_doujinshi", column: "pd_parent_id"
end
