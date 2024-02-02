class CreateProcessableDoujinDupes < ActiveRecord::Migration[7.1]
  def change
    create_table :processable_doujin_dupes do |t|
      t.references :pd_parent, null: false, foreign_key: { to_table: :processable_doujinshi }
      t.references :pd_child , null: false, foreign_key: { to_table: :processable_doujinshi }
      t.integer    :likeness , null: false

      t.datetime   :created_at
    end
  end
end
