class CreateAuthors < ActiveRecord::Migration[7.0]
  def change
    create_table :authors do |t|
      t.string  :name
      t.string  :name_romaji
      t.string  :name_kana
      t.string  :name_kakasi
      t.string  :url, null: false, default: ''
      t.text    :info
      t.text    :aliases
      t.text    :links
      t.integer :doujinshi_org_id

      t.timestamps
    end
  end
end
