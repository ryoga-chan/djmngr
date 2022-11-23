class CreateDoujinshiShelves < ActiveRecord::Migration[7.0]
  def change
    create_table :doujinshi_shelves do |t|
      t.references :doujin, null: false, foreign_key: true
      t.references :shelf , null: false, foreign_key: true
      t.integer    :position

      t.datetime   :created_at
    end
  end
end
