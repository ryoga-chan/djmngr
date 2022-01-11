class CreateSettings < ActiveRecord::Migration[7.0]
  def change
    create_table :settings do |t|
      t.string :key  , null: false
      t.string :value, null: false
      t.string :notes

      t.timestamps
    end
    
    Setting.create key: 'dir.to_sort', value: Rails.root.join('dj-libray', 'to-sort'), notes: 'folder containing doujinshi to process'
    Setting.create key: 'dir.sorted' , value: Rails.root.join('dj-libray', 'sorted' ), notes: 'folder containing the processed doujinshi'
  end
end
