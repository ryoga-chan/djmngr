class ProcessIndexRefreshJob < ApplicationJob
  LOCK_FILE  = File.join(Setting['dir.to_sort'], 'indexing.lock').to_s
  
  queue_as :tools

  def self.lock_file!     = FileUtils.touch(LOCK_FILE)
  def self.lock_file?     = File.exist?(LOCK_FILE)
  def self.rm_lock_file   = FileUtils.rm_f(LOCK_FILE)
  def self.entries        = ProcessableDoujin.order(:name)
  def self.rm_entry(path) = ProcessableDoujin.find_by(name: path).try(:destroy)
  
  def perform(*args)
    self.class.lock_file!
    
    ProcessableDoujin.transaction do
      ProcessableDoujin.delete_all
      
      files_glob = File.join Setting['dir.to_sort'], '**', '*.zip'
      Dir[files_glob].sort.each do |f|
        rel_name = Pathname.new(f).relative_path_from(Setting['dir.to_sort']).to_s
        ProcessableDoujin.create name: rel_name, name_kakasi: rel_name.to_romaji, size: File.size(f)
      end
    end
    
    self.class.rm_lock_file
  end # perform
end
