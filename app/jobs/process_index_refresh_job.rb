class ProcessIndexRefreshJob < ApplicationJob
  queue_as :tools

  def self.lock_file      = File.join(Setting['dir.to_sort'], 'indexing.lock').to_s
  def self.lock_file!     = FileUtils.touch(lock_file)
  def self.lock_file?     = File.exist?(lock_file)
  def self.rm_lock_file   = FileUtils.rm_f(lock_file)
  def self.entries        = ProcessableDoujin.order(:name)
  def self.rm_entry(path) = ProcessableDoujin.find_by(name: path).try(:destroy)
  
  def perform(*args)
    self.class.lock_file!
    
    ProcessableDoujin.transaction do
      ProcessIndexPreviewJob.rm_previews
      
      ProcessableDoujin.truncate_and_restart_sequence
      
      files_glob = File.join Setting['dir.to_sort'], '**', '*.zip'
      list = Dir[files_glob].sort
      list = list[0...100] unless Rails.env.production?
      list.each do |f|
        rel_name = Pathname.new(f).relative_path_from(Setting['dir.to_sort']).to_s
        ProcessableDoujin.create name: rel_name, name_kakasi: rel_name.to_romaji, size: File.size(f)
      end
    end
    
    self.class.rm_lock_file
  end # perform
end
