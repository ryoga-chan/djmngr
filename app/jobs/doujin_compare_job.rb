class DoujinCompareJob < ApplicationJob
  CHUNK_SIZE = 6
  THUMB_SIZE = { width: 320, height: 640 }.freeze # aspect 2/3, eg. 480x960

  queue_as :default
  
  def self.data_file = File.join(Setting['dir.sorting'], 'comparison.yml'.freeze).to_s
  
  def self.data
    comparison_data = YAML.unsafe_load_file(DoujinCompareJob.data_file) rescue []
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
      File.atomic_write(DoujinCompareJob.data_file){|f| f.puts comparison_data.to_yaml }
    end
    
    comparison_data
  end # self.data
  
  def self.remove(index)
    if index == 'all'.freeze
      FileUtils.rm_f DoujinCompareJob.data_file
    else
      comparison_data = DoujinCompareJob.data
      comparison_data.delete_at index.to_i
      File.atomic_write(DoujinCompareJob.data_file){|f| f.puts comparison_data.to_yaml }
    end
  end # self.remove

  def perform(rel_path: nil, full_path: nil, doujin: nil, mode: 'subset')
    comparison_data = DoujinCompareJob.data
    
    mode = 'subset' unless %w{ subset all }.include?(mode.to_s)
    
    info = { images: [], max_height: 0 }
    
    if full_path && rel_path && full_path.ends_with?(rel_path)
      return if comparison_data.any?{|entry| entry[:rel_path] == rel_path }
      info[:source   ] = :process
      info[:rel_path ] = rel_path
      info[:full_path] = full_path
      info[:file_size] = File.size full_path
    elsif doujin.is_a?(Doujin)
      return if comparison_data.any?{|entry| entry[:doujin_id] == doujin.id }
      info[:source   ] = :doujin
      info[:rel_path ] = doujin.file_path
      info[:full_path] = doujin.file_path full: true
      info[:doujin_id] = doujin.id
      info[:file_size] = doujin.size
    else
      return
    end
    
    return unless File.exist?(info[:full_path])
    
    Zip::File.open(info[:full_path]) do |zip|
      all_entries = zip.image_entries(sort: true)
      
      thumb_entries = mode == 'all' ?
        all_entries : all_entries.pages_preview(chunk_size: CHUNK_SIZE)
      
      info[:num_pages] = all_entries.size
      info[:sampled  ] = all_entries.size != thumb_entries.size
      
      thumb_entries.each do |e|
        thumb = Vips::Image.webp_cropped_thumb \
          e.get_input_stream.read,
          width: THUMB_SIZE[:width],
          height: THUMB_SIZE[:height],
          padding: false
        info[:max_height] = thumb[:height] if thumb[:height] > info[:max_height]
        info[:images] << { name: e.name, data: Base64.encode64(thumb[:image].webpsave_buffer).chomp }
      end
    end
    
    File.atomic_write(DoujinCompareJob.data_file){|f| f.puts comparison_data.push(info).to_yaml }
  end # perform
end
