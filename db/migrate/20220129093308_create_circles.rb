class CreateCircles < ActiveRecord::Migration[7.0]
  def change
    create_table :circles do |t|
      t.string   :name
      t.string   :name_romaji
      t.string   :name_kana
      t.string   :name_kakasi
      t.text     :info
      t.text     :aliases
      t.text     :links
      t.integer  :doujinshi_org_id
      t.string   :doujinshi_org_url, null: false, default: ''
      t.boolean  :favorite, default: false
      t.datetime :faved_at

      t.timestamps
    end

    add_index :circles, :doujinshi_org_id
  end
end
