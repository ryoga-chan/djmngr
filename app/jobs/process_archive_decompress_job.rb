class ProcessArchiveDecompressJob < ApplicationJob
  THUMB_WIDTH  = 160
  THUMB_HEIGHT = 240
  IMAGE_REGEXP = /\.(jpe*g|gif|png)$/i
  CROP_METHODS = %i{ low centre attention entropy high }

  queue_as :tools
  
  def self.file_hash(fname)
    Digest::SHA256.hexdigest "djmngr|#{File.basename fname}|#{File.size fname}"
  end # self.file_hash
  
  def self.prepare_and_perform(fname, perform_when: :later)
    raise :invalid_method unless %i[ later now ].include?(perform_when)
    raise :file_not_found unless File.exist?(fname)
    
    return :invalid_zip if Marcel::MimeType.for(Pathname.new fname) != 'application/zip'
    
    # create WIP folder named as the hash
    hash = file_hash fname
    dst_dir = File.join Setting['dir.sorting'], hash
    FileUtils.mkdir_p dst_dir
    
    if Dir.empty?(dst_dir)
      # create metadata file
      File.atomic_write(File.join(dst_dir, 'info.yml')) do |f|
        f.puts({
          file_path:     fname,
          file_size:     File.size(fname),
          relative_path: Pathname.new(fname).relative_path_from(Setting['dir.to_sort']).to_s,
          working_dir:   hash,
          prepared_at:   nil,
        }.to_yaml)
      end
      
      # create a symlink just in case of manual folder inspection (unsupported on windows)
      File.symlink fname, File.join(dst_dir, 'file.zip') if OS_LINUX
      
      ProcessArchiveDecompressJob.send "perform_#{perform_when}", dst_dir
    end
    
    hash
  end # self.prepare_and_perform
  
  def self.cover_path(dst_dir, info)
    path = info[:landscape_cover] ? '0000.webp' : info[:images].first[:thumb_path]
    File.join(dst_dir, 'thumbs', path).to_s
  end # self.cover_path
  
  # autogenerate portrait cover for landascape first image
  def self.crop_landscape_cover(dst_dir, info, crop_method = :attention)
    # get image dimensions
    cover_img = Vips::Image.new_from_file File.join(dst_dir, 'contents', info[:images].first[:src_path])
    info[:landscape_cover] = cover_img.width > cover_img.height
    info[:landscape_cover_method] = crop_method # see CROP_METHODS
    
    # generate cover
    if info[:landscape_cover]
      vips = \
        if CROP_METHODS.include?(crop_method.to_sym)
          # crop with standard VIPS methods
          # NOTE: using ProcessArchiveCompressJob sizes because the final output depends on resolution too!!
          ImageProcessing::Vips.source(cover_img).
            resize_to_fill(ProcessArchiveCompressJob::THUMB_WIDTH,
                           ProcessArchiveCompressJob::THUMB_HEIGHT,
                           crop: crop_method)
        else # crop at a specific percentage
          ImageProcessing::Vips.source cover_img.
            scale_and_crop_to_offset_perc(THUMB_WIDTH, THUMB_HEIGHT, crop_method.to_s.to_i)
        end
      
      vips.convert('webp').saver(quality: 70).call destination: File.join(dst_dir, 'thumbs', '0000.webp')
    end
  end # self.crop_landscape_cover
  
  # fast resize for thumbnail generation
  def self.generate_thumbnail(src, dst)
    ImageProcessing::Vips.source(src).
      resize_and_pad(THUMB_WIDTH, THUMB_HEIGHT, alpha: true).
      convert('webp').saver(quality: 70).call destination: dst
  end # self.generate_thumbnail

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
        info[:dest_folder] = (subject.name_romaji.present? ? subject.name_romaji : subject.name_kakasi).downcase.strip
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
    
    # set properties
    info[:language ] = Doujin::LANGUAGES.values.detect{|v| name[:properties].include?(v) } || Doujin::LANGUAGES.values.first
    info[:censored ] = !name[:properties].include?('unc')
    info[:colorized] = info[:file_type] == 'artbook' || name[:properties].include?('col')
    info[:hcg      ] = fname =~ /(hcg| cg | cg$)/i
    
    # create folder and unzip archive
    path_thumbs   = File.join(dst_dir, 'thumbs')
    path_contents = File.join(dst_dir, 'contents')
    path_cover    = File.join(dst_dir, 'cover')
    
    FileUtils.mkdir_p path_thumbs
    FileUtils.mkdir_p path_contents
    FileUtils.mkdir_p path_cover
    
    system %Q| unzip -q -d #{path_contents.shellescape} #{info[:file_path].shellescape} |
    
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
      partition{|i| i[:src_path] =~ IMAGE_REGEXP }
    
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
        
        ProcessArchiveDecompressJob.generate_thumbnail File.join(path_contents, img[:src_path]), tpath
        
        # optimize size
        #system %Q| cwebp -q 70 #{tpath.shellescape} -o #{tpath.shellescape} |
        #raise 'err' if $?.to_i != 0
      rescue
        img[:dst_path] = "RESIZE ERROR: #{$!}"
      end
      
      # write completion percentage
      perc = (i+1).to_f / info[:images].size * 100
      File.atomic_write(File.join(dst_dir, 'completion.perc')){|f| f.write perc.round(2) }
    end
    
    info[:reading_direction] = Setting[:reading_direction]
    info[:prepared_at] = Time.now
    
    File.atomic_write(File.join(dst_dir, 'info.yml')){|f| f.puts info.to_yaml }
  end # perform
end
