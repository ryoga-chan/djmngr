class CreateShelves < ActiveRecord::Migration[7.0]
  def change
    create_table :shelves do |t|
      t.string  :name
      t.integer :num_images

      t.datetime   :created_at
    end
  end
end
