class CreateAuthorsDoujinshi < ActiveRecord::Migration[7.0]
  def change
    create_table :authors_doujinshi, id: false do |t|
      t.references :author, null: false, foreign_key: true
      t.references :doujin, null: false, foreign_key: true

      t.datetime   :created_at
    end
    
    # unique combo
    add_index :authors_doujinshi, %i{author_id doujin_id}, unique: true
  end
end
