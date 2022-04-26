class CreateSettings < ActiveRecord::Migration[7.0]
  def change
    create_table :settings do |t|
      t.string :key  , null: false
      t.string :value, null: false
      t.string :notes

      t.timestamps
    end
    
    Setting.create key: 'dir.to_sort', value: Rails.root.join('dj-libray', 'to-sort').to_s, notes: 'folder containing doujinshi to process'
    Setting.create key: 'dir.sorting', value: Rails.root.join('dj-libray', 'sorting').to_s, notes: 'folder containing doujinshi under process'
    Setting.create key: 'dir.sorted' , value: Rails.root.join('dj-libray', 'sorted' ).to_s, notes: 'folder containing processed doujinshi'
    Setting.create key: 'reading_direction', value: 'r2l' # r2l, l2r
    Setting.create key: 'epub_img_width' , value: 768
    Setting.create key: 'epub_img_height', value: 1024
  end
end
