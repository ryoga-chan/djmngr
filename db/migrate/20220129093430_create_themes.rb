class CreateThemes < ActiveRecord::Migration[7.0]
  def change
    create_table :themes do |t|
      t.string  :name       , null: false
      t.string  :name_romaji
      t.string  :name_kana
      t.string  :name_kakasi, null: false
      t.text    :info
      t.text    :aliases
      t.text    :links
      t.integer :parent_id
      t.integer :doujinshi_org_id
      t.integer :doujinshi_org_aka_id
      t.string  :doujinshi_org_url, null: false, default: ''

      t.timestamps
    end
    
    add_index :themes, :doujinshi_org_id
    add_index :themes, :doujinshi_org_aka_id
  end
end
