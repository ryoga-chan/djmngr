class CreateSettings < ActiveRecord::Migration[7.0]
  def change
    create_table :settings do |t|
      t.string :key  , null: false
      t.string :value, null: false
      t.string :notes

      t.timestamps
    end
    
    Setting.create key: 'dir.to_sort'      , value: Rails.root.join('dj-libray', 'to-sort').to_s, notes: 'folder containing doujinshi to process'
    Setting.create key: 'dir.sorting'      , value: Rails.root.join('dj-libray', 'sorting').to_s, notes: 'folder containing doujinshi under process'
    Setting.create key: 'dir.sorted'       , value: Rails.root.join('dj-libray', 'sorted' ).to_s, notes: 'folder containing processed doujinshi'
    Setting.create key: 'reading_direction', value: 'r2l'      , notes: 'default reading direction' # r2l, l2r
    Setting.create key: 'reading_bg_color' , value: 'dark'     , notes: 'default reading background color' # white, smoke, dark, black
    Setting.create key: 'epub_img_width'   , value: 768        , notes: 'resize image to this width in epub creation'
    Setting.create key: 'epub_img_height'  , value: 1024       , notes: 'resize image to this height in epub creation'
    Setting.create key: 'comics_viewer'    , value: 'mcomix -f', notes: 'application for reading CBZ files (comic book viewer)'
    Setting.create key: 'file_manager'     , value: 'thunar'   , notes: 'application for browsing files (file manager)'
    Setting.create key: 'image_editor'     , value: 'gimp'     , notes: 'application for editing images (photo editor)'
    Setting.create key: 'terminal'         , value: 'xfce4-terminal', notes: 'default terminal emulator'
    Setting.create key: 'ext_cmd_env'      , value: '{"DISPLAY":":0"}', notes: 'environment variables for external commands'
    Setting.create key: 'scraper_useragent',                     notes: 'user agent used for doujinshi.org scraping',
      value: 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/103.0.0.0 Safari/537.36'
    Setting.create key: 'external_link'    , value: 'DJ.org|https://www.doujinshi.org', notes: 'additional menu item in the form "text|url"'
    Setting.create key: 'process_img_sel'  , value: '-', notes: 'image selection mode for "Images" tab in process section'
  end
end
