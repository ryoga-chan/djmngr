class CreateCirclesDoujinshi < ActiveRecord::Migration[7.0]
  def change
    create_table :circles_doujinshi, id: false do |t|
      t.references :circle, null: false, foreign_key: true
      t.references :doujin, null: false, foreign_key: true

      t.datetime   :created_at
    end
    
    add_index :circles_doujinshi, :circle_id
    add_index :circles_doujinshi, :doujin_id
    add_index :circles_doujinshi, %i{circle_id doujin_id}, unique: true # no duplicates
  end
end
