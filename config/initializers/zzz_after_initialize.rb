Rails.application.config.after_initialize do
  if Setting.table_exists?
    # create collection folders
    folders  = [ Setting['dir.to_sort'], Setting['dir.sorting'], Setting['dir.sorted'] ]
    folders += %w{ author circle magazine artbook }.map{|d| File.join(Setting['dir.sorted'], d).to_s }
    folders << File.join(Setting['dir.to_sort'], DJ_DIR_REPROCESS)
    folders << File.join(Setting['dir.to_sort'], DJ_DIR_PROCESS_LATER)
    folders.each{|f| FileUtils.mkdir_p f }
  end
end
