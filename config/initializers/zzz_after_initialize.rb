# https://stackoverflow.com/questions/73868603/accessing-models-and-modules-in-a-rails-7-initializer/73881810#73881810
Rails.application.config.after_initialize do
  ActiveRecord::Base.logger.silence do
    if Setting.table_exists?
      # create collection folders
      folders  = [ Setting['dir.to_sort'], Setting['dir.sorting'], Setting['dir.sorted'] ]
      folders += %w{ author circle magazine artbook }.map{|d| File.join(Setting['dir.sorted'], d).to_s }
      folders << File.join(Setting['dir.to_sort'], DJ_DIR_REPROCESS)
      folders << File.join(Setting['dir.to_sort'], DJ_DIR_PROCESS_LATER)
      folders.each{|f| FileUtils.mkdir_p f }
    end
  end
end
