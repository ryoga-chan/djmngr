class CreateCirclesThemes < ActiveRecord::Migration[7.0]
  def change
    create_table :circles_themes, id: false do |t|
      t.references :circle, null: false, foreign_key: true
      t.references :theme , null: false, foreign_key: true

      t.datetime   :created_at
    end
    
    # unique combo
    add_index :circles_themes, %i{circle_id theme_id}, unique: true
  end
end
