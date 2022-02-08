class ProcessArchiveCompressJob < ApplicationJob
  queue_as :tools

  def perform(src_dir)
    info = YAML.load_file(File.join src_dir, 'info.yml')
    
    begin
      out_dir = File.join src_dir, 'output'
      FileUtils.rm_rf out_dir, secure: true
      FileUtils.mkdir_p out_dir
      
      tot_steps = info[:images].size + 4
      cur_step  = 0
      
      # N. hard link/convert images to the new name/format
      Dir.chdir(out_dir) do
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
          source_file:    info[:relative_path],
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
        # compress sorting files alphabetically within archive
        File.unlink(info[:collection_full_path]) if File.exist?(info[:collection_full_path])
        system %Q[ find -type f | sort | zip -r #{info[:collection_full_path].shellescape} -@ ]
        
        perc = (cur_step+=1).to_f / tot_steps * 100
        File.open(File.join(src_dir, 'finalize.perc'), 'w'){|f| f.write perc.round(2) }
        
        # 3. calculate checksum
        info[:dest_checksum] = `sha512sum -b #{info[:collection_full_path].shellescape}`.split(' ', 2)[0]
        perc = (cur_step+=1).to_f / tot_steps * 100
        File.open(File.join(src_dir, 'finalize.perc'), 'w'){|f| f.write perc.round(2) }
      end

      # 4. save record on database
      Doujin.transaction do
        name = File.basename info[:dest_filename], File.extname(info[:dest_filename])
        d = Doujin.create! \
          name:         name,
          name_kakasi:  name.to_romaji,
          size:         File.size(info[:collection_full_path]),
          checksum:     info[:dest_checksum],
          num_images:   info[:images].size,
          num_files:    info[:files].size,
          score:        nil,
          path:         info[:collection_relative_path],
          name_orig:    info[:relative_path]
        d.author_ids = info[:author_ids] if info[:author_ids].try(:any?)
        d.circle_ids = info[:circle_ids] if info[:circle_ids].try(:any?)
      end
      perc = (cur_step+=1).to_f / tot_steps * 100
      File.open(File.join(src_dir, 'finalize.perc'), 'w'){|f| f.write perc.round(2) }
    rescue
      info[:finalize_error    ] = $!.to_s
      info[:finalize_backtrace] = $!.backtrace
    end
    
    File.open(File.join(src_dir, 'info.yml'), 'w'){|f| f.puts info.to_yaml }
  end # perform
end
