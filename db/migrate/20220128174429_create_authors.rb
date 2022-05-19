class CreateAuthors < ActiveRecord::Migration[7.0]
  def change
    create_table :authors do |t|
      t.string   :name       , null: false
      t.string   :name_romaji
      t.string   :name_kana
      t.string   :name_kakasi, null: false
      t.text     :info
      t.text     :aliases
      t.text     :links
      t.integer  :doujinshi_org_id
      t.integer  :doujinshi_org_aka_id
      t.string   :doujinshi_org_url, null: false, default: ''
      t.boolean  :favorite, default: false
      t.datetime :faved_at

      t.timestamps
    end
    
    add_index :authors, :doujinshi_org_id
    add_index :authors, :doujinshi_org_aka_id
  end
end
