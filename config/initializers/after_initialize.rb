# https://stackoverflow.com/questions/73868603/accessing-models-and-modules-in-a-rails-7-initializer/73881810#73881810
Rails.application.config.after_initialize do
  # create defaults
  if APP_MODE.in?(%i[ server console ])
    ActiveRecord::Base.logger.silence do
      if Setting.table_exists?
        # create default settings
        [
          { key: 'dir.to_sort'      , value: Rails.root.join('dj-library', 'to-sort').to_s, notes: 'folder containing doujinshi to process'   , startup: true },
          { key: 'dir.sorting'      , value: Rails.root.join('dj-library', 'sorting').to_s, notes: 'folder containing doujinshi under process', startup: true },
          { key: 'dir.sorted'       , value: Rails.root.join('dj-library', 'sorted' ).to_s, notes: 'folder containing processed doujinshi'    , startup: true },
          { key: 'reading_direction', value: 'r2l'      , notes: 'default reading direction' }, # r2l, l2r
          { key: 'reading_bg_color' , value: 'dark'     , notes: 'default reading background color' }, # white, smoke, dark, black
          { key: 'epub_devices'     , value: 'Kobo_Sage@1440x1920, Kobo_Glo@758x1024', notes: 'screen dimension of your devices, used for epub creation\ninput format = Name@WxH, Name2@WxH, ...' },
          { key: 'comics_viewer'    , value: 'mcomix -f', notes: 'application for reading CBZ files (comic book viewer)' },
          { key: 'file_manager'     , value: 'thunar'   , notes: 'application for browsing files (file manager)' },
          { key: 'file_picker'      , value: "zenity --file-selection --file-filter='*.zip *.cbz'", notes: 'application for file selection (prints file path to stdout)' },
          { key: 'image_editor'     , value: 'gimp'     , notes: 'application for editing images (photo editor)' },
          { key: 'terminal'         , value: 'xfce4-terminal', notes: 'default terminal emulator' },
          { key: 'ext_cmd_env'      , value: '{"DISPLAY":":0"}', notes: 'environment variables for external commands' },
          { key: 'scraper_useragent', value: 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/103.0.0.0 Safari/537.36', notes: 'user agent used for doujinshi.org scraping' },
          { key: 'external_link'    , value: 'DJ.org|https://www.doujinshi.org', notes: 'additional menu item, input format = "text|url"' },
          { key: 'process_img_sel'  , value: '-', notes: 'image selection mode for "Images" tab in process section' },
          { key: 'process_epp'      , value: 25, notes: 'entries per page in process section' },
          { key: 'process_aps'      , value: 0.6, notes: 'max average page size (in MiB) in process section (a warning is shown when exceeding this value)' },
          { key: 'basic_auth'       , value: '', notes: 'enable basic auth for PCs, input format = "user:password"' },
          { key: 'ehentai_auth'     , value: '', notes: 'optional ehentai credentials, input format = "user:password"' },
          { key: 'score_labels'     , value: 'Terrible,Poor,Satisfactory,Mediocre,Fair,Good,Very Good,Excellent,Outstanding,Perfect', notes: 'scoring tooltips (1-10), input format = "a,b,c,..."', startup: true },
          # image hashing max hamming distance -- less than ~20% (13/64) different bits
          { key: 'hd_phash'         , value: 13, notes: 'max hamming distance for pHash image similarity' , startup: true },
          { key: 'hd_sdhash'        , value: 13, notes: 'max hamming distance for sdHash image similarity', startup: true },
          # image save quality
          { key: 'img_q_thumb'      , value: 70, notes: 'default output quality for image thumbnails'     , startup: true },
          { key: 'img_q_resize'     , value: 80, notes: 'default output quality for image resizing'       , startup: true },
          # search engines
          { key: 'search_engine.00' , value: 'DD|https://duckduckgo.com/?q=', notes: 'search engine url, input format = "[-]label|url"', startup: true },
          { key: 'search_engine.01' , value: '-GG|https://www.google.com/search?q=', notes: 'search engine url, input format = "[-]label|url"', startup: true },
          { key: 'search_engine.02' , value: 'MU|https://www.mangaupdates.com/authors.html?search=', notes: 'search engine url, input format = "[-]label|url"', startup: true },
          { key: 'search_engine.03' , value: '', notes: 'search engine url, input format = "[-]label|url"', startup: true },
          { key: 'search_engine.04' , value: '', notes: 'search engine url, input format = "[-]label|url"', startup: true },
          { key: 'search_engine.05' , value: '', notes: 'search engine url, input format = "[-]label|url"', startup: true },
          { key: 'search_engine.06' , value: '', notes: 'search engine url, input format = "[-]label|url"', startup: true },
          { key: 'search_engine.07' , value: '', notes: 'search engine url, input format = "[-]label|url"', startup: true },
          { key: 'search_engine.08' , value: '', notes: 'search engine url, input format = "[-]label|url"', startup: true },
          { key: 'search_engine.09' , value: '', notes: 'search engine url, input format = "[-]label|url"', startup: true },
        ].each do |fields|
          fields[:startup] = false if fields[:startup].nil?
          s = Setting.find_or_initialize_by(fields.slice :key)

          if s.notes != fields[:notes] || s.startup != fields[:startup]
            attrs = fields.slice :notes, :startup
            attrs[:value] = fields[:value] if s.new_record?
            s.update attrs
          end
        end # each setting

        # create collection folders
        folders  = [ Setting['dir.to_sort'], Setting['dir.sorting'], Setting['dir.sorted'] ]
        folders += %w[ author circle magazine artbook ].map{|d| File.join(Setting['dir.sorted'], d).to_s }
        folders << File.join(Setting['dir.to_sort'], DJ_DIR_REPROCESS)
        folders << File.join(Setting['dir.to_sort'], DJ_DIR_PROCESS_LATER)
        folders.each{|f| FileUtils.mkdir_p f }
      end # if Setting.table_exists?
    end # ActiveRecord::Base.logger.silence
  end # create defaults
end
