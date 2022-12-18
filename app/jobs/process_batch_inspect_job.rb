class ProcessBatchInspectJob < ApplicationJob
  queue_as :tools

  def perform(hash)
    info_path = ProcessBatchJob.info_path(hash)
    info = YAML.load_file info_path
    
    info[:thumbs] = {}
    info[:files].keys.each do |name|
      file_path = File.join Setting['dir.to_sort'], name

      Zip::File.open(file_path) do |zip|
        image_entries = zip.entries.
          select{|e| e.file? && e.name =~ /\.(jpe*g|png|gif)$/i }.
          sort{|a,b| a.name <=> b.name }
      
        info[:files][name] = image_entries.map &:name
        
        if cover = image_entries.first # extract cover image
          info[:thumbs][name] = Base64.encode64 Vips::Image.
            webp_cropped_thumb_from_buffer(cover.get_input_stream.read, src_name: File.basename(cover.name))
        end
      end
      
      File.atomic_write(info_path){|f| f.puts info.to_yaml }
    end
    
    info[:prepared_at] = Time.now
    File.atomic_write(info_path){|f| f.puts info.to_yaml }
  end # perform
end
