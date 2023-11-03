class ProcessBatchInspectJob < ApplicationJob
  queue_as :tools

  def perform(hash)
    info_path = ProcessBatchJob.info_path(hash)
    info = YAML.unsafe_load_file info_path
    
    # TODO: rewrite using a single hash with multiple properties
    info[:thumbs] = {}
    info[:titles] = {}
    info[:sizes ] = {}
    info[:files].keys.each do |name|
      info[:titles][name] = File.basename(name).sub(/ *\.zip$/i, '')
      
      file_path = File.join Setting['dir.to_sort'], name
      info[:sizes][name] = File.size file_path

      Zip::File.open(file_path) do |zip|
        image_entries = zip.image_entries(sort: true)
      
        info[:files][name] = image_entries.map &:name
        
        if cover = image_entries.first # extract cover image
          thumb = Vips::Image.webp_cropped_thumb \
            cover.get_input_stream.read,
            width:  ProcessArchiveCompressJob::THUMB_WIDTH,
            height: ProcessArchiveCompressJob::THUMB_HEIGHT
          
          info[:thumbs][name] = { landscape: thumb[:landscape],
                                  base64:    Base64.encode64(thumb[:image].webpsave_buffer).chomp }
        end
      end
      
      File.atomic_write(info_path){|f| f.puts info.to_yaml }
    end
    
    info[:prepared_at] = Time.now
    File.atomic_write(info_path){|f| f.puts info.to_yaml }
  end # perform
end
