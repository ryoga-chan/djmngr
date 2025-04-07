class AddStartupToSettings < ActiveRecord::Migration[8.0]
  def change
    add_column :settings, :startup, :boolean, default: false
  end
end
