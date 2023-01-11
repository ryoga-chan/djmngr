class ProcessBatchInspectJob < ApplicationJob
  queue_as :tools

  def perform(hash)
    info_path = ProcessBatchJob.info_path(hash)
    info = YAML.unsafe_load_file info_path
    
    info[:thumbs] = {}
    info[:files].keys.each do |name|
      file_path = File.join Setting['dir.to_sort'], name

      Zip::File.open(file_path) do |zip|
        image_entries = zip.entries.
          select{|e| e.file? && e.name =~ RE_IMAGE_EXT }.
          sort{|a,b| a.name <=> b.name }
      
        info[:files][name] = image_entries.map &:name
        
        if cover = image_entries.first # extract cover image
          thumb = Vips::Image.webp_cropped_thumb \
            cover.get_input_stream.read,
            width:  ProcessArchiveCompressJob::THUMB_WIDTH,
            height: ProcessArchiveCompressJob::THUMB_HEIGHT
          
          info[:thumbs][name] = { landscape: thumb[:landscape],
                                  base64:    Base64.encode64(thumb[:buffer]).chomp }
        end
      end
      
      File.atomic_write(info_path){|f| f.puts info.to_yaml }
    end
    
    info[:prepared_at] = Time.now
    File.atomic_write(info_path){|f| f.puts info.to_yaml }
  end # perform
end
