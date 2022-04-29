class CreateDoujinshi < ActiveRecord::Migration[7.0]
  def change
    create_table :doujinshi do |t|
      t.string   :name
      t.string   :name_romaji
      t.string   :name_kakasi
      t.string   :name_orig
      t.integer  :size
      t.string   :checksum
      t.integer  :num_images
      t.integer  :num_files
      t.integer  :score
      t.datetime :scored_at
      t.string   :category
      t.text     :file_folder
      t.text     :file_name
      t.string   :notes
      t.string   :reading_direction, default: :r2l, limit: 3
      t.integer  :read_pages, default: 0
      t.string   :language,   default: :jpn, limit: 3
      t.boolean  :censored,   default: true
      t.boolean  :colorized,  default: false

      t.timestamps
    end
  end
end
