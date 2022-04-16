class ProcessArchiveCompressJob < ApplicationJob
  queue_as :tools

  def perform(src_dir)
    info = YAML.load_file(File.join src_dir, 'info.yml')
    
    begin
      out_dir = File.join src_dir, 'output'
      FileUtils.rm_rf out_dir, secure: true
      FileUtils.mkdir_p out_dir
      
      tot_steps = info[:images].size + 5
      cur_step  = 0
      
      Dir.chdir(out_dir) do
        # N. hard link/convert images to the new name/format
        info[:images].each do |img|
          src_path = File.join(src_dir, 'contents', img[:src_path])
          if File.extname(img[:src_path]).downcase == File.extname(img[:dst_path]).downcase
            if OS_LINUX
              File.link    src_path, img[:dst_path] # efficient copy via hard link
            else
              FileUtils.cp src_path, img[:dst_path]
            end
          else
            ImageProcessing::Vips.
              source(src_path).
              convert( File.extname(img[:dst_path]).downcase[1..-1] ).
              call destination: img[:dst_path]
          end
          
          perc = (cur_step+=1).to_f / tot_steps * 100
          File.open(File.join(src_dir, 'finalize.perc'), 'w'){|f| f.write perc.round(2) }
        end
        
        # 1. add metadata file
        File.open('metadata.yml', 'w'){|f| f.write({
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
        File.open(File.join(src_dir, 'finalize.perc'), 'w'){|f| f.write perc.round(2) }
        
        # 2. create zip file
        info[:collection_relative_path] = Doujin.dest_path_by_process_params info
        info[:collection_full_path] = File.join Setting['dir.sorted'], info[:collection_relative_path]
        FileUtils.mkdir_p File.dirname(info[:collection_full_path])
        # compress and sort files alphabetically within archive, overwrite already processed file
        File.unlink(info[:collection_full_path]) if File.exist?(info[:collection_full_path])
        system %Q[ find -type f | sort | zip -r #{info[:collection_full_path].shellescape} -@ ]
        
        perc = (cur_step+=1).to_f / tot_steps * 100
        File.open(File.join(src_dir, 'finalize.perc'), 'w'){|f| f.write perc.round(2) }
        
        # 3. calculate checksum
        info[:dest_checksum] = `sha512sum -b #{info[:collection_full_path].shellescape}`.split(' ', 2)[0]
        perc = (cur_step+=1).to_f / tot_steps * 100
        File.open(File.join(src_dir, 'finalize.perc'), 'w'){|f| f.write perc.round(2) }
      end

      Doujin.transaction do
        Doujin.find_by_process_params(info).try(:destroy) # overwrite already processed file
        
        # 4. save record on database
        name = File.basename info[:dest_filename], File.extname(info[:dest_filename])
        d = Doujin.create! \
          name:         name,
          name_kakasi:  name.to_romaji,
          size:         File.size(info[:collection_full_path]),
          checksum:     info[:dest_checksum],
          num_images:   info[:images].size,
          num_files:    info[:files].size,
          score:        (info[:score].to_i > 0 ? info[:score].to_i : nil),
          path:         info[:collection_relative_path],
          name_orig:    info[:relative_path],
          category:     info[:file_type]
        d.author_ids = info[:author_ids] if info[:author_ids].try(:any?)
        d.circle_ids = info[:circle_ids] if info[:circle_ids].try(:any?)
        info[:db_doujin_id] = d.id # this field marks the process as completed
        
        perc = (cur_step+=1).to_f / tot_steps * 100
        File.open(File.join(src_dir, 'finalize.perc'), 'w'){|f| f.write perc.round(2) }
        
        # 5. create doujin thumbnail (webp animated image with sample pages)
        # select thumbnails
        max_id = info[:images].size - 1
        thumb_ids = max_id == 0 ? [0] : [
          0,
          (max_id.to_f * 0.25).floor + 1,
          (max_id.to_f * 0.50).floor + 1,
          (max_id.to_f * 0.75).floor + 1,
        ].uniq
        thumb_src = thumb_ids.map{|i| File.join(src_dir, 'thumbs', info[:images][i][:thumb_path]).shellescape }
        thumb_dst = File.join(Rails.root, 'public', 'thumbs', "#{d.id}.webp")
        # merge selected thumbnails
        system %Q| img2webp -q 70 -lossy \
          -d 2000 #{thumb_src[0]} -d 1000 #{thumb_src[1..-1].join ' '} \
          -o #{thumb_dst.shellescape} |
        if $?.to_i != 0 # remove thumbnail if it goes wrong
          File.unlink(thumb_dst) if File.exist?(thumb_dst)
          raise "error [#{$?.to_i}] while creating thumbnails"
        end
        
        perc = (cur_step+=1).to_f / tot_steps * 100
        File.open(File.join(src_dir, 'finalize.perc'), 'w'){|f| f.write perc.round(2) }
      end
    rescue
      info[:finalize_error    ] = $!.to_s
      info[:finalize_backtrace] = $!.backtrace
    end
    
    File.open(File.join(src_dir, 'info.yml'), 'w'){|f| f.puts info.to_yaml }
  end # perform
end
