class DoujinCompareJob < ApplicationJob
  CHUNK_SIZE = 7
  DATAFILE = File.join(Setting['dir.sorting'], "comparison.yml").to_s.freeze

  queue_as :default
  
  def self.data
    comparison_data = YAML.unsafe_load_file(DATAFILE) rescue []
    num_entries = comparison_data.size
    
    # auto remove non existent entries
    comparison_data.delete_if do |entry|
      if entry[:source] == :process
        true unless File.exist?(entry[:full_path])
      elsif entry[:source] == :doujin
        true unless Doujin.exists?(id: entry[:doujin_id])
      end
    end
    # update data file
    if num_entries != comparison_data.size
      File.atomic_write(DATAFILE){|f| f.puts comparison_data.to_yaml }
    end
    
    comparison_data
  end # self.data
  
  def self.remove(index)
    if index == 'all'.freeze
      FileUtils.rm_f DATAFILE
    else
      comparison_data = DoujinCompareJob.data
      comparison_data.delete_at index.to_i
      File.atomic_write(DATAFILE){|f| f.puts comparison_data.to_yaml }
    end
  end # self.remove

  def perform(rel_path: nil, full_path: nil, doujin: nil)
    comparison_data = DoujinCompareJob.data
  
    info = { images: [] }
    
    if full_path && rel_path && full_path.ends_with?(rel_path)
      return if comparison_data.any?{|entry| entry[:rel_path] == rel_path }
      info[:source   ] = :process
      info[:rel_path ] = rel_path
      info[:full_path] = full_path
    elsif doujin.is_a?(Doujin)
      return if comparison_data.any?{|entry| entry[:doujin_id] == doujin.id }
      info[:source   ] = :doujin
      info[:rel_path ] = doujin.file_path
      info[:full_path] = doujin.file_path full: true
      info[:doujin_id] = doujin.id
    else
      return
    end
    
    return unless File.exist?(info[:full_path])
    
    Zip::File.open(info[:full_path]) do |zip|
      all_entries = zip.entries.select{|e| e.file? && e.name =~ RE_IMAGE_EXT }
      thumb_entries = []
      
      # select 3 sets of `chunk_size` images (start/middle/end)
      if all_entries.size > (CHUNK_SIZE*3)
        gap = (all_entries.size - CHUNK_SIZE*3)/2 # number of images for a single gap
        thumb_entries.concat all_entries[0...CHUNK_SIZE]
        thumb_entries.concat all_entries[gap+CHUNK_SIZE, CHUNK_SIZE]
        thumb_entries.concat all_entries[(-CHUNK_SIZE)..-1]
      else
        thumb_entries = all_entries
      end
      
      thumb_entries.each do |e|
        thumb = Vips::Image.webp_cropped_thumb e.get_input_stream.read,
          width: 480, height: 960, padding: false
        info[:images] << { name: e.name, data: Base64.encode64(thumb[:buffer]).chomp }
      end
    end
    
    File.atomic_write(DATAFILE){|f| f.puts comparison_data.push(info).to_yaml }
  end
end
