class ProcessIndexPreviewJob < ProcessIndexRefreshJob
  THUMB_WIDTH  = 320
  THUMB_HEIGHT = 640
  THUMBS_CHUNK = 3
  THUMBS_NUM   = Rails.env.production? ? ProcessController::ROWS_PER_PAGE : 3
  
  def self.rm_previews
    pattern = Rails.root.join('public', ProcessableDoujin::THUMB_FOLDER, '*.webp').to_s
    Dir[pattern].each{|f| FileUtils.rm_f f }
  end # self.rm_previews
  
  def perform(id: nil, order: nil)
    self.class.lock_file!
    
    rel = self.class.entries(order: order)
    rel = rel.where(id: id) if id
    rel.page(1).per(THUMBS_NUM).each do |processable_doujin|
      next if File.exist?(processable_doujin.thumb_path)
      
      Zip::File.open(File.join Setting['dir.to_sort'], processable_doujin.name) do |zip|
        zip_images = zip.image_entries(sort: true)
        processable_doujin.update images: zip_images.size
        
        thumb_entries = zip_images.pages_preview(chunk_size: THUMBS_CHUNK)
        
        images = thumb_entries.map{|e|
          Vips::Image.webp_cropped_thumb(
            e.get_input_stream.read,
            width:   THUMB_WIDTH,
            height:  THUMB_HEIGHT,
            padding: false
          )[:image]
        }.compact
        
        # https://github.com/libvips/ruby-vips/blob/master/lib/vips/methods.rb#L362
        # create a long thumbnail for desktop
        collage = Vips::Image.arrayjoin images
        collage.write_to_file processable_doujin.thumb_path(mobile: false)
        # create a portrait thumbnail for mobile
        collage = Vips::Image.arrayjoin images, across: THUMBS_CHUNK
        collage.write_to_file processable_doujin.thumb_path(mobile: true)
      end
    end

    self.class.rm_lock_file
  end # perform
end
