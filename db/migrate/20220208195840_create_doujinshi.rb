class CreateDoujinshi < ActiveRecord::Migration[7.0]
  def change
    create_table :doujinshi do |t|
      t.string   :name       , null: false
      t.string   :name_romaji
      t.string   :name_kakasi, null: false
      t.string   :name_orig  , null: false
      t.string   :name_orig_kakasi, null: false
      t.string   :name_eng
      t.integer  :size       , null: false
      t.string   :checksum   , null: false
      t.integer  :num_images , null: false
      t.integer  :num_files  , null: false
      t.integer  :score
      t.datetime :scored_at
      t.string   :category   , null: false
      t.text     :file_folder, null: false
      t.text     :file_name  , null: false
      t.string   :notes
      t.string   :reading_direction, default: :r2l, limit: 3
      t.integer  :read_pages, default: 0
      t.string   :language,   default: :jpn, limit: 3
      t.boolean  :censored,   default: true
      t.boolean  :colorized,  default: false
      t.boolean  :favorite,   default: false
      t.string   :media_type, default: 'doujin' # doujin, manga, cg, artbook
      t.datetime :faved_at
      t.date     :released_at
      t.integer  :cover_phash
      t.integer  :cover_sdhash

      t.timestamps
    end
  end
end
