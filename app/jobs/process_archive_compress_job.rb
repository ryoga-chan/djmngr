class ProcessArchiveCompressJob < ApplicationJob
  THUMB_WIDTH  = 240
  THUMB_HEIGHT = 360

  queue_as :tools

  def perform(src_dir)
    info = YAML.unsafe_load_file(File.join src_dir, 'info.yml')

    begin
      out_dir = File.join src_dir, 'output'
      FileUtils.rm_rf out_dir, secure: true
      FileUtils.mkdir_p out_dir

      tot_steps = info[:images].size + 5
      cur_step  = 0

      # N. hard link/convert images to the new name/format
      info[:images].each do |img|
        # force lowercase extension
        dst_ext  = File.extname img[:dst_path]
        img[:dst_path] = img[:dst_path].sub(dst_ext, dst_ext.downcase)

        src_path = File.join(src_dir, 'contents', img[:src_path])
        if File.extname(img[:src_path]).downcase == File.extname(img[:dst_path]).downcase
          dst_path = File.join(out_dir, img[:dst_path])
          FileUtils.cp_hard src_path, dst_path
        else
          ImageProcessing::Vips.
            source(src_path).
            convert( File.extname(img[:dst_path]).downcase[1..-1] ).
            call destination: File.join(out_dir, img[:dst_path])
        end

        perc = (cur_step+=1).to_f / tot_steps * 100
        File.atomic_write(File.join(src_dir, 'finalize.perc')){|f| f.write perc.round(2) }
      end

      # 1. add metadata file
      File.atomic_write(File.join(out_dir, 'metadata.yml')){|f| f.write({
        source_file:    File.basename(info[:relative_path]),
        file_size:      info[:file_size],
        file_type:      info[:file_type],
        dest_folder:    info[:dest_folder],
        dest_subfolder: info[:subfolder],
        dest_filename:  info[:dest_filename],
        images: info[:images].map{|i| "#{i[:dst_path]}\t#{i[:src_path]}" },
        files:  info[:files ].map{|i| "#{i[:dst_path]}\t#{i[:src_path]}" },
      }.to_yaml) }
      perc = (cur_step+=1).to_f / tot_steps * 100
      File.atomic_write(File.join(src_dir, 'finalize.perc')){|f| f.write perc.round(2) }

      # 2. create zip file
      info[:collection_relative_path] = Doujin.dest_path_by_process_params info
      info[:collection_full_path] = File.join Setting['dir.sorted'], info[:collection_relative_path]
      FileUtils.mkdir_p File.dirname(info[:collection_full_path])
      # compress and sort files alphabetically within archive, overwrite already processed file
      File.unlink "#{info[:collection_full_path]}.NEW" if File.exist?("#{info[:collection_full_path]}.NEW")
      system %Q( find -type f | sort | zip -q -r #{info[:collection_full_path].shellescape}.NEW -@ ), chdir: out_dir

      perc = (cur_step+=1).to_f / tot_steps * 100
      File.atomic_write(File.join(src_dir, 'finalize.perc')){|f| f.write perc.round(2) }

      # 3. calculate checksum
      info[:dest_checksum] = `sha512sum -b #{info[:collection_full_path].shellescape}.NEW`.split(' ', 2)[0]
      perc = (cur_step+=1).to_f / tot_steps * 100
      File.atomic_write(File.join(src_dir, 'finalize.perc')){|f| f.write perc.round(2) }

      Doujin.transaction do
        # look for the eventual file already in collection
        prev_doujin = Doujin.find_by_process_params info

        # 4. save record on database
        name = info[:dest_title].present? ? info[:dest_title] : File.basename(info[:dest_filename], '.*')
        d = Doujin.new \
          name:         name,
          name_romaji:  info[:dest_title_romaji],
          name_kakasi:  name.to_romaji,
          name_eng:     info[:dest_title_eng],
          size:         File.size("#{info[:collection_full_path]}.NEW"),
          checksum:     info[:dest_checksum],
          num_images:   info[:images].size,
          num_files:    info[:files].size,
          score:        (info[:score].to_i > 0 ? info[:score].to_i : nil),
          category:     (info[:file_type] == 'doujin' ? info[:doujin_dest_type] : info[:file_type]),
          file_folder:  File.dirname(info[:collection_relative_path]),
          file_name:    File.basename(info[:collection_relative_path]),
          name_orig:    info[:relative_path].sub(/^#{DJ_DIR_REPROCESS}\//, '').sub(/^#{DJ_DIR_PROCESS_LATER}\//, ''),
          reading_direction: info[:reading_direction],
          language:     info[:language],
          censored:     info[:censored],
          colorized:    info[:colorized],
          media_type:   info[:media_type],
          notes:        info[:notes]
        d.file_folder = Pathname.new(d.file_folder).relative_path_from("/#{d.category}").to_s
        d.save!

        d.author_ids = info[:author_ids] if info[:author_ids].try(:any?)
        d.circle_ids = info[:circle_ids] if info[:circle_ids].try(:any?)

        # used in ProcessController#finalize_volume to skip the redirect to edit
        info[:db_doujin_id] = d.id

        perc = (cur_step+=1).to_f / tot_steps * 100
        File.atomic_write(File.join(src_dir, 'finalize.perc')){|f| f.write perc.round(2) }

        # 5. create doujin thumbnail (webp animated image with sample pages)
        # select thumbnails in predefined positions
        max_idx = info[:images].size - 1
        img_indexes = max_idx == 0 ? [0] : [
          0,
          (max_idx.to_f * 0.25).floor + 1,
          (max_idx.to_f * 0.50).floor + 1,
          (max_idx.to_f * 0.75).floor + 1,
        ].uniq
        # convert them to webp thumbnails
        thumb_src = []
        thumb_dst = File.join(Rails.root, 'public', 'thumbs', "#{d.id}.webp")
        img_indexes.each_with_index do |img_index, i|
          dst_img = File.join(src_dir, 'cover', "cover-000#{i}.webp")
          thumb_src << dst_img.shellescape

          vips_img = Vips::Image.new_from_file File.join(src_dir, 'contents', info[:images][img_index][:src_path])
          vips = ImageProcessing::Vips.source vips_img
          vips = \
            if vips_img.width > vips_img.height # is a landscape image
              if i > 0 # first image is the cover
                vips.resize_to_fill(THUMB_WIDTH, THUMB_HEIGHT, crop: :attention)
              elsif ProcessArchiveDecompressJob::CROP_METHODS.include?(info[:landscape_cover_method].to_sym)
                vips.resize_to_fill(THUMB_WIDTH, THUMB_HEIGHT, crop: info[:landscape_cover_method])
              else
                ImageProcessing::Vips.source vips_img.
                  scale_and_crop_to_offset_perc(THUMB_WIDTH, THUMB_HEIGHT, info[:landscape_cover_method].to_s.to_i)
              end
            else
              vips.resize_and_pad(THUMB_WIDTH, THUMB_HEIGHT, alpha: true)
            end

          vips.convert('webp').saver(quality: IMG_QUALITY_THUMB).call destination: dst_img
        end
        # merge selected thumbnails
        cmd  = %Q( img2webp -q 70 -lossy -d 3000 #{thumb_src[0]} )
        cmd += %Q( -d 2000 #{thumb_src[1..-1].join ' '} ) if thumb_src.size > 1
        cmd += %Q( -o #{thumb_dst.shellescape} )
        # https://docs.ruby-lang.org/en/3.0/Open3.html#method-c-capture2e
        sh_output, sh_status = Open3.capture2e cmd  # hide STDOUT (instead of "system cmd")
        if sh_status.exitstatus != 0 # remove thumbnail if it goes wrong
          File.unlink(thumb_dst) if File.exist?(thumb_dst)
          raise "merge thumbnails exit code [#{sh_status.exitstatus}] != 0"
        end
        # save hash cover image to DB
        d.cover_fingerprint!

        # delete the eventual file already in collection
        prev_doujin.try(:destroy_with_files)
        # rename temporary file into his final destination
        FileUtils.mv "#{info[:collection_full_path]}.NEW", info[:collection_full_path], force: true

        perc = (cur_step+=1).to_f / tot_steps * 100
        File.atomic_write(File.join(src_dir, 'finalize.perc')){|f| f.write perc.round(2) }
      end # Doujin.transaction

      CoverMatchingJob.rm_results_file info[:cover_hash]
    rescue
      info[:finalize_error    ] = $!.to_s
      info[:finalize_backtrace] = $!.backtrace
    end

    File.atomic_write(File.join(src_dir, 'info.yml')){|f| f.puts info.to_yaml }
  end # perform
end
