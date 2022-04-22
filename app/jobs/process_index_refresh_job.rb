class ProcessIndexRefreshJob < ApplicationJob
  CACHE_FILE = Rails.root.join('tmp','files.to_sort').to_s
  LOCK_FILE  = Rails.root.join('tmp','files.to_sort.lock').to_s
  
  queue_as :tools

  def self.lock_file!   = FileUtils.touch(LOCK_FILE)
  def self.lock_file?   = File.exist?(LOCK_FILE)
  def self.rm_lock_file = FileUtils.rm_f(LOCK_FILE)
  def self.cache_file?  = File.exist?(CACHE_FILE)
  def self.read_cache   = YAML.load_file(CACHE_FILE)
  
  def perform(*args)
    self.class.lock_file!
    
    files_glob = File.join Setting['dir.to_sort'], '**', '*.zip'
    files = Dir[files_glob].sort.inject({}){|h, f|
      rel_name = Pathname.new(f).relative_path_from(Setting['dir.to_sort']).to_s
      h.merge rel_name => File.size(f)
    }
    File.open(CACHE_FILE, 'w'){|f| f.puts files.to_yaml }

    self.class.rm_lock_file
  end # perform
end
