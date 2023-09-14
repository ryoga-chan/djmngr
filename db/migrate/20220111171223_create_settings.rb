class CreateSettings < ActiveRecord::Migration[7.0]
  def change
    create_table :settings do |t|
      t.string :key  , null: false
      t.string :value, null: false
      t.string :notes

      t.timestamps
    end
  end
end
