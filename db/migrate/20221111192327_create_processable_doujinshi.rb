class CreateProcessableDoujinshi < ActiveRecord::Migration[7.0]
  def change
    create_table :processable_doujinshi do |t|
      t.string   :name       , null: false
      t.string   :name_kakasi, null: false
      t.integer  :size       , null: false
      t.datetime :mtime
      t.integer  :images
      t.integer  :cover_phash
      t.integer  :cover_sdhash
      t.string   :notes

      t.datetime :created_at
    end
  end
end
