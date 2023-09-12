class ProcessIndexRefreshJob < ApplicationJob
  queue_as :tools

  def self.lock_file      = File.join(Setting['dir.to_sort'], 'indexing.lock').to_s
  def self.lock_file!     = FileUtils.touch(lock_file)
  def self.lock_file?     = File.exist?(lock_file)
  def self.rm_lock_file   = FileUtils.rm_f(lock_file)
  def self.entries        = ProcessableDoujin.order(:name)
  
  def self.rm_entry(path_or_id, track: false, rm_zip: false)
    pd = ProcessableDoujin.find_by(id: path_or_id.to_i) ||
         ProcessableDoujin.find_by(name: path_or_id)
    return false unless pd
    
    zip_path = pd.file_path full: true
    
    if track
      cover_hash = nil
    
      # count images and other files
      file_counters = { num_images: 0, num_files: 0 }
      Zip::File.open(zip_path) do |zip|
        zip.entries.sort_by_method(:name).each do |e|
          next unless e.file?
          
          is_image = e.name =~ RE_IMAGE_EXT
          
          # generate phash for the first image file
          if cover_hash.nil? && is_image
            cover_hash = CoverMatchingJob.hash_image_buffer(e.get_input_stream.read)[:phash]
          end
          
          file_counters[is_image ? :num_images : :num_files] += 1
        end
      end
      
      # track deletion
      name = pd.name.tr(File::SEPARATOR, ' ')
      dd = DeletedDoujin.create! file_counters.merge({
        name:             name,
        name_kakasi:      name.to_romaji,
        size:             File.size(zip_path),
      })
      dd.cover_fingerprint! cover_hash if cover_hash.present?
    end # if track
    
    # remove file from disk
    File.unlink zip_path if rm_zip && File.exist?(zip_path)
    
    pd.destroy
  end # self.rm_entry
  
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
