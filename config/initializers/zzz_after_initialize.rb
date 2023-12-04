# https://stackoverflow.com/questions/73868603/accessing-models-and-modules-in-a-rails-7-initializer/73881810#73881810
Rails.application.config.after_initialize do
  ActiveRecord::Base.logger.silence do
    if Setting.table_exists?
      # create default settings
      [
        { key: 'dir.to_sort'      , value: Rails.root.join('dj-libray', 'to-sort').to_s, notes: 'folder containing doujinshi to process' },
        { key: 'dir.sorting'      , value: Rails.root.join('dj-libray', 'sorting').to_s, notes: 'folder containing doujinshi under process' },
        { key: 'dir.sorted'       , value: Rails.root.join('dj-libray', 'sorted' ).to_s, notes: 'folder containing processed doujinshi' },
        { key: 'reading_direction', value: 'r2l'      , notes: 'default reading direction' }, # r2l, l2r
        { key: 'reading_bg_color' , value: 'dark'     , notes: 'default reading background color' }, # white, smoke, dark, black
        { key: 'epub_devices'     , value: 'Kobo_Sage@1440x1920, Kobo_Glo@758x1024', notes: 'screen dimension of your devices, used for epub creation' },
        { key: 'comics_viewer'    , value: 'mcomix -f', notes: 'application for reading CBZ files (comic book viewer)' },
        { key: 'file_manager'     , value: 'thunar'   , notes: 'application for browsing files (file manager)' },
        { key: 'file_picker'      , value: "zenity --file-selection --file-filter='*.zip *.cbz'", notes: 'application for file selection (prints file path to stdout)' },
        { key: 'image_editor'     , value: 'gimp'     , notes: 'application for editing images (photo editor)' },
        { key: 'terminal'         , value: 'xfce4-terminal', notes: 'default terminal emulator' },
        { key: 'ext_cmd_env'      , value: '{"DISPLAY":":0"}', notes: 'environment variables for external commands' },
        { key: 'scraper_useragent', value: 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/103.0.0.0 Safari/537.36', notes: 'user agent used for doujinshi.org scraping' },
        { key: 'external_link'    , value: 'DJ.org|https://www.doujinshi.org', notes: 'additional menu item, input format = "text|url"' },
        { key: 'process_img_sel'  , value: '-', notes: 'image selection mode for "Images" tab in process section' },
        { key: 'basic_auth'       , value: '', notes: 'enable basic auth for PCs, input format = "user:password"' },
        { key: 'search_engine.00' , value: 'DD|https://duckduckgo.com/?q=', notes: 'search engine url, input format = "[-]label|url", restart app after update' },
        { key: 'search_engine.01' , value: '-GG|https://www.google.com/search?q=', notes: 'search engine url, input format = "[-]label|url", restart app after update' },
        { key: 'search_engine.02' , value: 'MU|https://www.mangaupdates.com/authors.html?search=', notes: 'search engine url, input format = "[-]label|url", restart app after update' },
        { key: 'search_engine.03' , value: '', notes: 'search engine url, input format = "[-]label|url", restart app after update' },
        { key: 'search_engine.04' , value: '', notes: 'search engine url, input format = "[-]label|url", restart app after update' },
        { key: 'search_engine.05' , value: '', notes: 'search engine url, input format = "[-]label|url", restart app after update' },
        { key: 'search_engine.06' , value: '', notes: 'search engine url, input format = "[-]label|url", restart app after update' },
        { key: 'search_engine.07' , value: '', notes: 'search engine url, input format = "[-]label|url", restart app after update' },
        { key: 'search_engine.08' , value: '', notes: 'search engine url, input format = "[-]label|url", restart app after update' },
        { key: 'search_engine.09' , value: '', notes: 'search engine url, input format = "[-]label|url", restart app after update' },
      ].each do |fields|
        Setting.find_or_initialize_by(fields.slice :key).update fields.slice(:value, :notes) unless Setting[fields[:key]]
      end

      # create collection folders
      folders  = [ Setting['dir.to_sort'], Setting['dir.sorting'], Setting['dir.sorted'] ]
      folders += %w{ author circle magazine artbook }.map{|d| File.join(Setting['dir.sorted'], d).to_s }
      folders << File.join(Setting['dir.to_sort'], DJ_DIR_REPROCESS)
      folders << File.join(Setting['dir.to_sort'], DJ_DIR_PROCESS_LATER)
      folders.each{|f| FileUtils.mkdir_p f }
    end
  end

  # change process title
  # https://stackoverflow.com/questions/4603704/how-can-i-detect-if-my-code-is-running-in-the-console-in-rails-3
  if Rails.const_defined?(:Console)
    Process.setproctitle "ruby:djmngr-console" # $0 = title
  else
    # do it after webserver start (puma changes the title too)
    Thread.new{
      title = "ruby:djmngr-server"
      loop {
        sleep 1
        res = HTTPX.head('http://localhost:39102/')&.status rescue 404
        Process.setproctitle title # $0 = title
        break if res == 200
      }# loop
      Rails.logger.info %Q|process title changed to "#{title}"|
    }# Thread.new
  end
end
