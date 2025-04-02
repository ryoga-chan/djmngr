class CreateDeletedDoujinshi < ActiveRecord::Migration[7.0]
  def change
    create_table :deleted_doujinshi do |t|
      # downloaded file name
      t.string   :name       , null: false
      t.string   :name_kakasi, null: false
      # file name assigned after processing
      t.string   :alt_name
      t.string   :alt_name_kakasi
      # other info
      t.integer  :size       , null: false
      t.integer  :num_images , null: false
      t.integer  :num_files  , null: false
      t.boolean  :merged, default: false

      # data from the eventual already processed file
      t.integer  :doujin_id
      t.integer  :cover_phash
      t.integer  :cover_sdhash

      t.datetime :created_at
    end
  end
end
