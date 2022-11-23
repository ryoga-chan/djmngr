class CreateShelves < ActiveRecord::Migration[7.0]
  def change
    create_table :shelves do |t|
      t.string :name

      t.datetime   :created_at
    end
  end
end
