class CreateAuthorsCircles < ActiveRecord::Migration[7.0]
  def change
    create_table :authors_circles, id: false do |t|
      t.references :author, null: false, foreign_key: true
      t.references :circle, null: false, foreign_key: true

      t.datetime   :created_at
    end
    
    # unique combo
    add_index :authors_circles, %i{author_id circle_id}, unique: true
  end
end
