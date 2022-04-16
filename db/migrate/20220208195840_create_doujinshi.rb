class CreateDoujinshi < ActiveRecord::Migration[7.0]
  def change
    create_table :doujinshi do |t|
      t.string  :name
      t.string  :name_romaji
      t.string  :name_kakasi
      t.string  :name_orig
      t.integer :size
      t.string  :checksum
      t.integer :num_images
      t.integer :num_files
      t.string  :category
      t.integer :score
      t.text    :path

      t.timestamps
    end
  end
end
