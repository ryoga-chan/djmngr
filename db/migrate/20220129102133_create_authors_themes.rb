class CreateAuthorsThemes < ActiveRecord::Migration[7.0]
  def change
    create_table :authors_themes, id: false do |t|
      t.references :author, null: false, foreign_key: true
      t.references :theme , null: false, foreign_key: true

      t.datetime   :created_at
    end
    
    add_index :authors_themes, :author_id
    add_index :authors_themes, :theme_id
    add_index :authors_themes, %i{author_id theme_id}, unique: true # no duplicates
  end
end
