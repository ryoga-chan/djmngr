class ProcessIndexRefreshJob < ApplicationJob
  queue_as :tools
  
  ORDER = {
    '🔼 name'  => :name,
    '🔽 name'  => :name_d,
    '🔼 xlate' => :kakasi,
    '🔽 xlate' => :kakasi_d,
    '🔼 time'  => :time,
    '🔽 time'  => :time_d,
    '🔼 size'  => :size,
    '🔽 size'  => :size_d,
  }

  around_perform do |job, block|
    self.class.lock_file!
    block.call
    self.class.rm_lock_file
    self.class.rm_progress_file
  end # around_perform
  
  def self.lock_file      = File.join(Setting['dir.to_sort'], 'indexing.lock').to_s
  def self.lock_file!     = FileUtils.touch(lock_file)
  def self.lock_file?     = File.exist?(lock_file)
  def self.rm_lock_file   = FileUtils.rm_f(lock_file)
  
  def self.description      = :'indexing files'
  def self.progress_file    = File.join(Setting['dir.sorting'], 'process-job.progress').to_s
  def self.rm_progress_file = FileUtils.rm_f(progress_file)
  def self.progress
    text = File.read(progress_file) rescue nil
    text || "#{description} @ --% (--/--)"
  end # self.progress
  def self.progress_update(step:, steps:, msg: nil)
    text = "#{msg || description} @ #{(step/steps.to_f*100).to_i}% (#{step}/#{steps})"
    File.atomic_write(progress_file){|f| f.write text }
    text
  end # self.progress_update
  
  def self.entries(order: 'name')
    order_clause = case order
      when 'name'    .freeze then :name
      when 'name_d'  .freeze then {name: :desc}
      when 'kakasi'  .freeze then Arel.sql("replace(name_kakasi, ' ', '')")
      when 'kakasi_d'.freeze then Arel.sql("replace(name_kakasi, ' ', '') DESC")
      when 'time'    .freeze then :mtime
      when 'time_d'  .freeze then {mtime: :desc}
      when 'size'    .freeze then :size
      when 'size_d'  .freeze then {size: :desc}
      else :name
    end
    
    ProcessableDoujin.order(order_clause)
  end # self.entries
  
  def self.rm_entry(path_or_id, track: false, rm_zip: false)
    pd = ProcessableDoujin.find_by(id: path_or_id.to_i) ||
         ProcessableDoujin.find_by(name: path_or_id)
    return false unless pd
    
    zip_path = pd.file_path full: true
    
    if File.exist?(zip_path)
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
      File.unlink zip_path if rm_zip
    end
    
    pd.destroy
  end # self.rm_entry
  
  def self.add_entry(full_path)
    fs = File.stat full_path
    rel_name = Pathname.new(full_path).relative_path_from(Setting['dir.to_sort']).to_s
    ProcessableDoujin.create name: rel_name, name_kakasi: rel_name.to_romaji,
      size: fs.size, mtime: fs.mtime
  end # self.add_entry
  
  def perform(*args)
    ProcessableDoujin.transaction do
      ProcessIndexPreviewJob.rm_previews
      ProcessableDoujin.truncate_and_restart_sequence
      
      files_glob = File.join Setting['dir.to_sort'], '**', '*.zip'
      list = Dir[files_glob].sort
      list = list[0...100] unless Rails.env.production?
      list.each_with_index do |f, i|
        self.class.progress_update step: i+1, steps: list.size
        self.class.add_entry f
      end
    end # transaction
  end # perform
end
