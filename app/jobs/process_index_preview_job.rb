class ProcessIndexPreviewJob < ProcessIndexRefreshJob
  THUMB_WIDTH  = 320
  THUMB_HEIGHT = 640
  THUMBS_CHUNK = 3
  
  def self.description = :'generating previews'
  
  def self.rm_previews
    pattern = Rails.root.join('public', ProcessableDoujin::THUMB_FOLDER, '*.webp').to_s
    Dir[pattern].each{|f| FileUtils.rm_f f }
  end # self.rm_previews
  
  def self.img_not_found
    @@img_not_found ||= Vips::Image.webp_cropped_thumb(
      File.read(Rails.root.join('public', 'not-found.png').to_s),
      width:   THUMB_WIDTH,
      height:  THUMB_HEIGHT,
      padding: false
    )[:image]
  end # self.img_not_found
  
  def self.img_transparent
    # https://github.com/libvips/pyvips/issues/326
    @@img_trasparent ||= Vips::Image.
      black(2,2). # with x height in pixels
      copy(interpretation: "srgb").
      new_from_image([0, 0, 0, 0])
  end # self.img_transparent
  
  def perform(id: nil, order: nil, page: nil)
    page = 1 if page.to_i <= 0
    
    rel = self.class.entries(order: order)
    rel = rel.where(id: id) if id
    
    # generate preview for two pages
    records  = rel.page(p.to_i  ).per(Setting[:process_epp].to_i).to_a
    records += rel.page(p.to_i+1).per(Setting[:process_epp].to_i).to_a
    
    records.each_with_index do |processable_doujin, i|
      self.class.progress_update step: i+1, steps: records.size
      self.class.generate_preview processable_doujin
    end
  end # perform
  
  def self.generate_preview(processable_doujin)
    return if File.exist?(processable_doujin.thumb_path)
    
    fname = File.join Setting['dir.to_sort'], processable_doujin.name
    return unless File.exist?(fname)
    
    Zip::File.open(fname) do |zip|
      zip_images = zip.image_entries(sort: true)
      processable_doujin.update images: zip_images.size
      
      thumb_entries = zip_images.pages_preview(chunk_size: THUMBS_CHUNK)
      
      images = thumb_entries.map{|e|
        i = Vips::Image.webp_cropped_thumb(
          e.get_input_stream.read,
          width:   THUMB_WIDTH,
          height:  THUMB_HEIGHT,
          padding: false
        )[:image]
        
        # https://github.com/libvips/pyvips/issues/202
        # https://github.com/libvips/libvips/issues/1525
        i = i.colourspace('srgb') if i.bands  < 3
        i = i.bandjoin(255)       if i.bands == 3
        
        i
      }.compact
      
      # display missing image if no images are found
      images << self.class.img_not_found if images.empty?
      
      # use transparent images for the remaining thumbs
      num_fill = (images.size.to_f / 3).ceil * 3
      images += (images.size ... num_fill).map{ self.img_transparent }
      
      # https://github.com/libvips/ruby-vips/blob/master/lib/vips/methods.rb#L362
      # create a long thumbnail for desktop
      collage = Vips::Image.arrayjoin images, background: 0
      collage.write_to_file processable_doujin.thumb_path(mobile: false)
      # create a portrait thumbnail for mobile
      collage = Vips::Image.arrayjoin images, background: 0, across: THUMBS_CHUNK
      collage.write_to_file processable_doujin.thumb_path(mobile: true)
    end
  end # self.generate_preview
end
