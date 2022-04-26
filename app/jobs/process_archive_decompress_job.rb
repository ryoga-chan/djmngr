class ProcessArchiveDecompressJob < ApplicationJob
  THUMB_WIDTH  = 160
  THUMB_HEIGHT = 240

  queue_as :tools
  
  # autogenerate portrait cover for landascape first image
  def self.crop_landscape_cover(dst_dir, info, crop_method = :low)
    # get image dimensions
    cover_img = Vips::Image.new_from_file File.join(dst_dir, 'contents', info[:images].first[:src_path])
    info[:landscape_cover] = cover_img.width > cover_img.height
    info[:landscape_cover_method] = crop_method # [:low, :centre, :attention, :entropy, :high]
    
    # generate cover
    if info[:landscape_cover]
      ImageProcessing::Vips.source(cover_img).
        resize_to_fill(THUMB_WIDTH, THUMB_HEIGHT, crop: crop_method).
        convert('webp').saver(quality: 70).call destination: File.join(dst_dir, 'thumbs', '0000.webp')
    end
  end # self.crop_landscape_cover

  def perform(dst_dir)
    info = YAML.load_file(File.join dst_dir, 'info.yml')
    
    fname = File.basename(info[:relative_path].to_s).downcase

    # auto associate doujin authors/circles when a 100% match is found
    name = fname.parse_doujin_filename
    (name[:ac_explicit] + name[:ac_implicit]).each do |term|
      # fine authors/circles and use only the first one by name
      list  = Author.search_by_name(term, limit: 50).inject({}){|h,i| h.merge i.name.downcase => i }.values
      list += Circle.search_by_name(term, limit: 50).inject({}){|h,i| h.merge i.name.downcase => i }.values
      list.each do |result|
        key = "#{result.class.name.downcase}_ids".to_sym
        info[key] ||= []
        info[key] << result.id if result.name.downcase == term
      end
    end
    # set a default doujin destination
    if dest_id = info[:circle_ids].to_a.first
      info[:doujin_dest_type], info[:doujin_dest_id] = 'circle', dest_id
    elsif dest_id = info[:author_ids].to_a.first
      info[:doujin_dest_type], info[:doujin_dest_id] = 'author', dest_id
    end
    
    # identify file type and name
    if name[:subjects].present?
      info[:file_type] = 'doujin'

      # set destination folder to subject romaji name
      if info[:doujin_dest_type] && info[:doujin_dest_id]
        subject = info[:doujin_dest_type].capitalize.constantize.find_by(id: info[:doujin_dest_id])
        info[:dest_folder] = (subject.name_romaji || subject.name_kakasi).downcase
      end
      
      # suggest the romaji title
      info[:dest_filename] = name[:fname].to_romaji.sub(/ *\.zip$/i, '.zip')
    elsif fname =~ /^([^0-9]+)[ 0-9\-]+\.zip$/i
      info[:file_type] = 'magazine'
      info[:dest_folder] = $1.strip
      info[:dest_filename] = File.basename(fname).sub($1.to_s, '').strip
    else
      info[:file_type] = 'artbook'
      info[:dest_folder] = ''
      info[:dest_filename] = File.basename(fname)
    end
    
    # identify files and resize images
    path_thumbs   = File.join(dst_dir, 'thumbs')
    path_contents = File.join(dst_dir, 'contents')
    
    FileUtils.mkdir_p path_thumbs
    FileUtils.mkdir_p path_contents
    
    system %Q| unzip -d #{path_contents.shellescape} #{info[:file_path].shellescape} |
    
    # reset file/folder permissions
    if OS_LINUX
      dirs, files = Dir[File.join path_contents, '**/**'].partition{|i| File.directory? i }
      FileUtils.chmod 0755, dirs
      FileUtils.chmod 0644, files
    end

    # detect images and other files
    info[:images], info[:files] = Dir[File.join path_contents, '**', '*'].
      sort.select{|i| File.file? i }.
      map{|i| { src_path: Pathname.new(i).relative_path_from(path_contents).to_s, size: File.size(i) } }.
      partition{|i| i[:src_path] =~ /\.(jpe*g|gif|png)$/i }
    
    info[:ren_images_method] = 'alphabetical_index'
    
    # copy filename for files
    info[:files].each_with_index{|f, i| f[:dst_path] = "#{'%04d' % i}-#{f[:src_path].gsub '/', '_'}" }
    
    # autogenerate portrait cover for landascape first image
    self.class.crop_landscape_cover dst_dir, info
    
    # create thumbnails for the images
    info[:images].each_with_index do |img, i|
      begin
        num = '%04d' % (i+1)
        img[:dst_path  ] = "#{num}#{File.extname img[:src_path]}"
        img[:thumb_path] = "#{num}.webp"
        
        tpath = File.join(path_thumbs, img[:thumb_path])
        
        # fast resize
        ImageProcessing::Vips.source(File.join path_contents, img[:src_path]).
          resize_and_pad(THUMB_WIDTH, THUMB_HEIGHT, alpha: true).
          convert('webp').saver(quality: 70).call destination: tpath
        
        # optimize size
        #system %Q| cwebp -q 70 #{tpath.shellescape} -o #{tpath.shellescape} |
        #raise 'err' if $?.to_i != 0
      rescue
        img[:dst_path] = "RESIZE ERROR: #{$!}"
      end
      
      # write completion percentage
      perc = (i+1).to_f / info[:images].size * 100
      File.open(File.join(dst_dir, 'completion.perc'), 'w'){|f| f.write perc.round(2) }
    end
    
    info[:reading_direction] = Setting[:reading_direction]
    info[:prepared_at] = Time.now
    
    File.open(File.join(dst_dir, 'info.yml'), 'w'){|f| f.puts info.to_yaml }
  end # perform
end
