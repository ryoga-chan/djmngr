class ProcessArchiveDecompressJob < ApplicationJob
  THUMB_WIDTH  = 160
  THUMB_HEIGHT = 240
  CROP_METHODS = %i[ low centre attention entropy high ]

  queue_as :tools

  def self.file_hash(fname)
    Digest::SHA256.hexdigest "djmngr|#{File.basename fname}|#{File.size fname}"
  end # self.file_hash

  def self.rm_entry(path: nil, folder: nil)
    if path
      fpath = File.join Setting['dir.to_sort'], path
      dir = File.join(Setting['dir.sorting'], file_hash(fpath)) if File.exist?(fpath)
    end

    dir = folder if folder

    FileUtils.rm_rf dir, secure: true if dir && File.exist?(dir)
  end # sefl.rm_entry

  def self.prepare_and_perform(fname_or_ids, perform_when: :later, title: nil)
    raise :invalid_method unless %i[ later now ].include?(perform_when)
    
    fnames   = []
    tot_size = 0
    
    if fname_or_ids.is_a?(Array)
      ProcessableDoujin.where(id: fname_or_ids).each do |pd|
        fnames   << pd.file_path(full: true)
        tot_size += pd.size
      end
      author = File.basename(fnames.first.to_s).sub(/^(\[[^\]]+\]).+/, '\1')
      title = "#{author} #{fnames.size} merged files.zip"
    else
      fnames   = [fname_or_ids]
      tot_size = File.size fname_or_ids
    end
    
    raise :file_not_found unless fnames.all?{|i| File.exist? i }
    return :invalid_zip if fnames.any?{|i| Marcel::MimeType.for(Pathname.new i) != 'application/zip' }

    # create WIP folder
    hash = fnames.one? ? file_hash(fnames.first) : SecureRandom.uuid
    dst_dir = File.join Setting['dir.sorting'], hash
    FileUtils.mkdir_p dst_dir

    if Dir.empty?(dst_dir) # create metadata file
      File.atomic_write(File.join(dst_dir, 'info.yml')) do |f|
        f.puts({
          file_path:     fnames,
          file_size:     tot_size,
          relative_path: fnames.map{|i| Pathname.new(i).relative_path_from(Setting['dir.to_sort']).to_s },
          title:         title, # optional title from batch processing
          working_dir:   hash,
          prepared_at:   nil,
        }.to_yaml)
      end

      # create a symlink just in case of manual folder inspection (unsupported on windows)
      fnames.each_with_index{|f,i| File.symlink f, File.join(dst_dir, "file_#{'%03d' % i}.zip") } if OS_LINUX

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

      vips.convert('webp').saver(quality: IMG_QUALITY_THUMB).
        call destination: File.join(dst_dir, 'thumbs', '0000.webp')
    end
  end # self.crop_landscape_cover

  # fast resize for thumbnail generation (cwebp -q in.webp out.webp)
  def self.generate_thumbnail(src, dst)
    ImageProcessing::Vips.source(src).
      resize_and_pad(THUMB_WIDTH, THUMB_HEIGHT, alpha: true).
      convert('webp').saver(quality: IMG_QUALITY_THUMB).call destination: dst
  end # self.generate_thumbnail

  def self.duplicate_cover(dst_dir, info, save_info: false)
    # duplicate first image in "xxx_d0"
    dst_data = info[:images].first.clone
    dst_data[:src_path  ] = dst_data[:src_path  ].add_suffix_to_filename :_d0
    dst_data[:dst_path  ] = dst_data[:dst_path  ].add_suffix_to_filename :_d0
    dst_data[:thumb_path] = dst_data[:thumb_path].add_suffix_to_filename :_d0
    FileUtils.cp_f File.join(dst_dir, 'contents', info[:images].first[:src_path]),
                   File.join(dst_dir, 'contents', dst_data[:src_path])
    FileUtils.cp_f File.join(dst_dir, 'thumbs'  , info[:images].first[:thumb_path]),
                   File.join(dst_dir, 'thumbs'  , dst_data[:thumb_path])

    # rename original image in "xxx_d1"
    src_data = info[:images].first.clone
    src_data[:src_path  ] = src_data[:src_path  ].add_suffix_to_filename :_d1
    src_data[:dst_path  ] = src_data[:dst_path  ].add_suffix_to_filename :_d1
    src_data[:thumb_path] = src_data[:thumb_path].add_suffix_to_filename :_d1
    FileUtils.mv File.join(dst_dir, 'contents', info[:images].first[:src_path]),
                 File.join(dst_dir, 'contents', src_data[:src_path]), force: true
    FileUtils.mv File.join(dst_dir, 'thumbs'  , info[:images].first[:thumb_path]),
                 File.join(dst_dir, 'thumbs'  , src_data[:thumb_path]), force: true

    # update current cover image data
    info[:images].first.merge! src_data

    # prepend duplicate image details to images array
    info[:images].unshift dst_data

    # update data file
    File.open(File.join(dst_dir, 'info.yml'), 'w'){|f| f.puts info.to_yaml } if save_info

    info
  end # self.duplicate_cover

  def self.inject_file(file_name, file_path, dst_dir, info, save_info: false)
    ts = "zz#{Time.now.strftime '%Y%M%d%H%M%S%9N'}"

    dst_data = {
      src_path: "#{ts}-#{File.basename file_name}",
      dst_path: File.basename(file_name),
      size:     File.size(file_path),
    }

    if file_path.is_image_filename?
      dst_data[:alt_label ] = dst_data[:src_path]
      dst_data[:thumb_path] = "#{ts}.webp"

      info[:images] = info[:images].push(dst_data).sort_by_method('[]', :dst_path)

      FileUtils.cp_f file_path, File.join(dst_dir, 'contents', dst_data[:src_path])

      ProcessArchiveDecompressJob.generate_thumbnail \
        File.join(dst_dir, 'contents', dst_data[:src_path  ]),
        File.join(dst_dir, 'thumbs'  , dst_data[:thumb_path])
    else
      info[:files].push dst_data
    end

    # update data file
    File.open(File.join(dst_dir, 'info.yml'), 'w'){|f| f.puts info.to_yaml } if save_info

    info
  end # self.inject_file

  def self.refresh_cover_thumb(dst_dir, info, save_info: false)
    # refresh image thumb and master image
    ProcessArchiveDecompressJob.generate_thumbnail \
      File.join(dst_dir, 'contents', info[:images].first[:src_path  ]),
      File.join(dst_dir, 'thumbs'  , info[:images].first[:thumb_path])
    FileUtils.cp_f \
      File.join(dst_dir, 'thumbs'  , info[:images].first[:thumb_path]),
      File.join(dst_dir, 'thumbs'  , '0000.webp')

    # update data file
    img = Vips::Image.new_from_file File.join(dst_dir, 'contents', info[:images].first[:src_path  ])
    info[:landscape_cover] = img.is_landscape?

    File.open(File.join(dst_dir, 'info.yml'), 'w'){|f| f.puts info.to_yaml } if save_info

    info
  end # self.refresh_cover_thumb

  def self.rotate_cover(dst_dir, info, dir:, save_info: false)
    fname = File.join(dst_dir, 'contents', info[:images].first[:src_path])

    # rotate image 90 degrees clockwise/counter clockwise
    Vips::Image.
      new_from_buffer(File.binread(fname), '').
      rot(dir == 'right' ? 1 : 3).
      write_to_file fname, Q: IMG_QUALITY_RESIZE

    ProcessArchiveDecompressJob.refresh_cover_thumb dst_dir, info, save_info: save_info
  end # self.refresh_cover_thumb

  def perform(dst_dir)
    info = YAML.unsafe_load_file(File.join dst_dir, 'info.yml')

    # parse the title from batch processing or the relative filename
    fname = info[:title] || File.basename(info[:relative_path].first.to_s).downcase

    # copy notes from ProcessableDoujin
    notes = info[:relative_path].
      map{|rp| ProcessableDoujin.find_by(name: rp.to_s)&.notes }.
      compact.join("\n")
    info[:notes] = notes if notes.present?

    # auto associate doujin authors/circles when a 100% match is found
    name = fname.parse_doujin_filename
    (name[:ac_explicit] + name[:ac_implicit]).each do |term|
      a = Author.search_by_name(term).first || Author.new
      c = Circle.search_by_name(term).first || Circle.new
      if a.attributes.slice(*%w[ name name_romaji name_kana name_kakasi ]).values.compact.map(&:downcase).include?(term)
        info[:author_ids] ||= []
        info[:author_ids] << a.id
      end
      if c.attributes.slice(*%w[ name name_romaji name_kana name_kakasi ]).values.compact.map(&:downcase).include?(term)
        info[:circle_ids] ||= []
        info[:circle_ids] << c.id
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

      # suggest titles and filename
      info[:dest_filename    ] = name[:fname].to_romaji.sub(/ *\.zip$/i, '.zip')
      info[:dest_title       ] = name[:fname].sub(/ *\.zip$/i, '')
    elsif fname =~ /^([^0-9]+)[ 0-9\-]+\.zip$/i
      info[:file_type    ] = 'magazine'
      info[:dest_folder  ] = $1.strip
      info[:dest_filename] = File.basename(fname).sub($1.to_s, '').strip
      info[:dest_title   ] = fname.tr(File::SEPARATOR, ' ').sub(/ *\.zip$/i, '')
    else
      info[:file_type    ] = 'artbook'
      info[:dest_folder  ] = ''
      info[:dest_filename] = File.basename(fname)
      info[:dest_title   ] = info[:dest_filename].sub(/ *\.zip$/i, '')
    end

    %i[ dest_title dest_filename ].each{|k| info[k] = info[k].gsub(/ +/, ' ') }
    info[:orig_title        ] = info[:dest_title]
    info[:orig_dest_filename] = info[:dest_filename]

    # set properties
    info[:language  ]   = Doujin::LANGUAGES.
      detect{|descr, lbl| name[:properties].include?(lbl) || fname.include?(descr.downcase) }.
      try('[]', 1) || Doujin::LANGUAGES.values.first
    info[:censored  ] = !(name[:properties].include?('unc') || %w[ decensored uncensored ].any?{|t| fname.include? t })
    info[:colorized ] = info[:file_type] == 'artbook' || name[:properties].include?('col')
    info[:media_type] = (fname =~ /(hcg| cg | cg$)/i ? 'cg' : 'doujin')
    info[:media_type] = 'artbook' if info[:file_type] == 'artbook'

    # restore reprocessing metadata
    info[:file_path].each do |i|
      md_path = File.join File.dirname(i), "#{File.basename i, File.extname(i)}.yml"
      md_info = YAML.unsafe_load_file(md_path) rescue {}
      if File.exist?(md_path) && md_info.is_a?(Hash)
        info.merge! md_info
        File.unlink md_path
        break
      end
    end

    # create folder and unzip archive
    path_thumbs   = File.join(dst_dir, 'thumbs')
    path_contents = File.join(dst_dir, 'contents')
    path_cover    = File.join(dst_dir, 'cover')

    FileUtils.mkdir_p path_thumbs
    FileUtils.mkdir_p path_contents
    FileUtils.mkdir_p path_cover

    if info[:file_path].one?
      system %Q( unzip -q -d #{path_contents.shellescape} #{info[:file_path].first.shellescape} )
    else
      info[:file_path].sort.each_with_index do |file_path, i|
        pd = ProcessableDoujin.find_by name: info[:relative_path][i]
        title = pd&.notes.present? ? pd&.notes : file_path
        path = File.join path_contents,
          i.to_s.rjust(3,'0'),
          title.to_romaji.tokenize_doujin_filename(title_only: true).join(' ')
        FileUtils.mkdir_p path
        system %Q( unzip -q -d #{path.shellescape} #{file_path.shellescape} )
      end
    end

    # reset file/folder permissions
    if OS_LINUX
      dirs, files = Dir[File.join path_contents, '**/**'].partition{|i| File.directory? i }
      FileUtils.chmod 0755, dirs
      FileUtils.chmod 0644, files
    end

    # remove reprocessing files
    Dir[File.join path_contents, '**/metadata.yml'].each{|f| FileUtils.rm_f f }
    
    # fix invalid files names
    all_files = Dir[File.join path_contents, '**', '*'].map do |f|
      if f.valid_encoding?
        f
      else
        f_fixed = f.encode('UTF-8', invalid: :replace, undef: :replace, replace: rand(10000).to_s.rjust(4,'0'))
        File.rename f, f_fixed
        f_fixed
      end
    end

    # detect images and other files
    info[:images], info[:files] = all_files.
      select{|i| File.file? i }.
      map{|i| { src_path: Pathname.new(i).relative_path_from(path_contents).to_s, size: File.size(i) } }.
      partition{|i| i[:src_path].is_image_filename? }

    # append notes from file and delete it
    info[:files].select{|i| i[:src_path].include? 'notes.txt' }.each do |notes_element|
      notes_file = File.join path_contents, notes_element[:src_path]
      info[:notes] = "#{info[:notes]}\n#{File.read(notes_file)}".strip
      info[:files].delete notes_element
      File.unlink notes_file
    end
    
    # auto rename images with default method
    if info[:file_path].one?
      info[:ren_images_method] = ZipImagesRenamer::DEFAULT_METHOD.to_s
      info[:images] = ZipImagesRenamer.rename(info[:images]).sort_by_method('[]', :dst_path)
    else
      # rename files: /###/subfolder/(x/y/z/...)/image.jpg => ###_subfolder_image.jpg
      sep = File::SEPARATOR
      sep = sep*2 if sep == '\\'
      info[:ren_images_method      ] = 'regex_replacement'
      info[:images_last_regexp     ] = "([0-9]{3})#{sep}([^#{sep}]+)#{sep}(.+#{sep})*(.+)"
      info[:images_last_regexp_repl] = '\\1__\\2__\\4'
      info[:images] = ZipImagesRenamer.rename(
        info[:images],
        info[:ren_images_method].to_sym,
        rename_regexp:      info[:images_last_regexp     ],
        rename_regexp_repl: info[:images_last_regexp_repl]
      ).sort_by_method('[]', :dst_path)
    end
    
    # copy filename for files
    info[:files].each_with_index{|f, i| f[:dst_path] = "#{'%04d' % i}-#{f[:src_path].gsub '/', '_'}" }
    info[:files] = info[:files].sort_by_method('[]', :dst_path)

    # autogenerate portrait cover for landascape first image
    self.class.crop_landscape_cover dst_dir, info if info[:images].any?

    # create thumbnails for the images
    info[:images].each_with_index do |img, i|
      begin
        img[:thumb_path] = "#{'%04d' % (i+1)}.webp"
        tpath = File.join(path_thumbs, img[:thumb_path])
        ProcessArchiveDecompressJob.generate_thumbnail File.join(path_contents, img[:src_path]), tpath
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
