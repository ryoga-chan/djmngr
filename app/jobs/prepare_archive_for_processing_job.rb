class PrepareArchiveForProcessingJob < ApplicationJob
  queue_as :tools

  def perform(dst_dir)
    # TODO: run bg job: unzip file, create thumbs
    #   on finish: update metadata
    info = YAML.load_file(File.join dst_dir, 'info.yml')
    
    path_thumbs   = File.join(dst_dir, 'thumbs')
    path_contents = File.join(dst_dir, 'contents')
    
    FileUtils.mkdir_p path_thumbs
    FileUtils.mkdir_p path_contents
    
    system %Q| unzip -d #{path_contents.shellescape} #{info[:file_path].shellescape} |
    
    # detect images and other files
    info[:images], info[:files] = Dir
      .chdir(path_contents){
        Dir['**/*']
          .sort.select{|i| File.file? i }
          .map{|i| { src_path: i, size: File.size(i) } }
      }.partition{|i| i[:src_path] =~ /\.(jpe*g|gif|png)$/i }
    
    info[:ren_images_method] = 'alphabetical_index'
    
    # create thumbnails for the images
    info[:images].each_with_index do |img, i|
      begin
        img[:dst_path] = '%04d.jpg' % i
        img[:thumb_path] = img[:dst_path].dup
        
        ImageProcessing::Vips
          .source(File.join path_contents, img[:src_path])
          .convert('jpg')
          .resize_to_fit(100, 140)
          .call destination: File.join(path_thumbs, img[:dst_path])
      rescue
        img[:dst_path] = 'RESIZE ERROR'
      end
      
      # write completion percentage
      perc = (i+1).to_f / info[:images].size * 100
      File.open(File.join(dst_dir, 'completion.perc'), 'w'){|f| f.write perc.round(2) }
    end
    
    info[:prepared_at] = Time.now
    
    File.open(File.join(dst_dir, 'info.yml'), 'w'){|f| f.puts info.to_yaml }
  end # perform
end
