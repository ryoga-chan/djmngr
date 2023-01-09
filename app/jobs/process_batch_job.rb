class ProcessBatchJob < ApplicationJob
  queue_as :tools
  
  def self.info_path(hash)
    File.join Setting['dir.sorting'], "batch_#{hash}.yml"
  end # self.info_path
  
  def self.prepare(pd_ids)
    names = ProcessableDoujin.where(id: pd_ids).order(:name).pluck(:name)
    hash  = Digest::SHA256.hexdigest "djmngr|#{names.join '|'}|#{Time.now}"
    
    File.atomic_write(info_path hash) do |f|
      f.puts({
        files:       names.inject({}){|h,n| h.merge n => nil }, # {name: array_of_filesname}
        prepared_at: nil,
      }.to_yaml)
    end
    
    # extract files names and covers for user inspection before processing
    ProcessBatchInspectJob.perform_later hash
    
    hash
  end # self.prepare

  def perform(doujin_id, files, options = {})
    raise %Q|ERROR: doujin ID [#{doujin_id}] not found| unless dj = Doujin.find_by(id: doujin_id)
    
    def update_batch_info(results, options)
      return unless options[:hash]
      
      batch_info_path = ProcessBatchJob.info_path options[:hash]
      return unless File.exist?(batch_info_path)
      
      batch_info = YAML.unsafe_load_file batch_info_path
      batch_info[:progress] = results
      File.atomic_write(batch_info_path){|f| f.puts batch_info.to_yaml }
    end # update_batch_info
    
    def add_error(results, key, msg, opts)
      results[key][:errors] ||= []
      results[key][:errors] << msg
      
      update_batch_info results, opts
      
      print ColorizedString['ERROR'].black.on_red
      puts  ColorizedString[" #{msg}"].red
    end # add_error
    
    results = {}
    
    # fill results with each files to process
    files.each do |dj_fname|
      puts '-'*70
      puts "FILE: #{dj_fname}"
      
      fname = File.expand_path dj_fname
      results[fname] = {}
      
      unless File.exist?(fname)
        add_error results, fname, 'not found', options
        next
      end
      
      unless fname.start_with?(Setting['dir.to_sort'])
        add_error results, fname, 'outside "to_sort"', options
        next
      end
      
      hash = ProcessArchiveDecompressJob.prepare_and_perform fname, perform_when: :now
      if hash == :invalid_zip
        add_error results, fname, 'not a ZIP file', options
        next
      end
      
      dname = File.expand_path File.join(Setting['dir.sorting'], hash)
      info_fname = File.join dname, 'info.yml'
      info  = YAML.unsafe_load_file info_fname
      puts "HASH: #{hash}"
      
      if info[:images].empty?
        add_error results, fname, 'no images found', options
        next
      end
      
      puts "\n[DST]     [SRC]"
      puts info[:images].map{|i| "#{i[:dst_path]}  #{i[:src_path]}"}
      if info[:files].any?
        puts "--------  --------------------"
        puts info[:files].map{|i| "#{i[:dst_path]}  #{i[:src_path]}"}
      end; puts "\n"
      
      # copy data from source doujin
      info[:file_type    ] = dj.category
      if %w{ author circle }.include?(dj.category)
        info[:file_type       ] = 'doujin'
        info[:doujin_dest_type] = dj.category
      end
      info[:dest_folder  ], info[:subfolder] = dj.file_folder.split(File::SEPARATOR)
      info[:dest_title   ] = options[:dest_title] if options[:dest_title].present?
      info[:score        ] = options[:score] if options[:score]
      info[:reading_direction] = dj.reading_direction
      
      info[:language         ] = options[:lang] if options[:lang].present? # dj.language
      info[:censored         ] = options[:unc ] if options[:unc ].present? # dj.censored
      info[:colorized        ] = options[:col ] if options[:col ].present? # dj.colorized
      info[:hcg              ] = options[:hcg ] if options[:hcg ].present? # dj.hcg
      info[:overwrite        ] = true if options[:overwrite]
      
      info[:dest_filename] = options[:dest_filename] if options[:dest_filename]
      info[:dest_filename] = File.basename(fname).sub(/ *\.zip$/i, '.zip') if options[:keep_filename]
      info[:author_ids   ] = dj.author_ids
      info[:circle_ids   ] = dj.circle_ids
      File.open(info_fname, 'w'){|f| f.puts info.to_yaml }
      
      # run cover image hash matching
      cover_path = ProcessArchiveDecompressJob.cover_path dname, info
      info[:cover_hash] = CoverMatchingJob.hash_image cover_path
      CoverMatchingJob.perform_now info[:cover_hash]
      cover_matching = CoverMatchingJob.results info[:cover_hash]
      info[:cover_results] = cover_matching[:results]
      info[:cover_status ] = cover_matching[:status]
      File.open(info_fname, 'w'){|f| f.puts info.to_yaml }
      if info[:cover_results].any?
        add_error results, fname, 'cover matching', options
        next
      end
      
      if !options[:overwrite] && File.exist?(Doujin.dest_path_by_process_params(info, full_path: true))
        add_error results, fname, 'already exists', options
        next
      end
      
      if info[:landscape_cover] && !options[:keep_cover].include?(dj_fname)
        add_error results, fname, 'landscape cover', options
        next
      end
      
      perc_file = File.join(dname, 'finalize.perc')
      unless File.exist?(perc_file)
        FileUtils.touch perc_file
        ProcessArchiveCompressJob.perform_now dname
        
        info = YAML.unsafe_load_file info_fname
        if info[:finalize_error].blank?
          puts "DjID: #{info[:db_doujin_id]}"
          results[fname][:id] = info[:db_doujin_id].to_i
          # remove file on disk, WIP folder, index entry
          File.unlink info[:file_path]
          FileUtils.rm_rf dname, secure: true
          ProcessIndexRefreshJob.rm_entry info[:relative_path]
        else
          add_error results, fname, 'processing errors', options # [#{info[:finalize_error]}]
          next
        end
      end
      
      update_batch_info results, options
    end # each filename
    
    # print final report
    if files.many?
      puts '~~~~~ o ~~~~~ o ~~~~~ o ~~~~~ o ~~~~~ o ~~~~~ o ~~~~~ o ~~~~~ o ~~~~~'
      base_dir, max_len = Setting['dir.to_sort'], 18
      results.keys.sort.partition{|k| results[k][:id] }.flatten.each do |k|
        fname = Pathname.new(k).relative_path_from(base_dir).to_s
        if results[k][:id]
          print ColorizedString['OK'].white.on_green
          print ColorizedString[" #{results[k][:id].to_s.ljust max_len}"].green
          puts  "| #{fname}"
        end
        
        results[k][:errors].to_a.each do |msg|
          print ColorizedString['KO'].black.on_red
          print ColorizedString[" #{msg.ljust max_len}"].red
          puts"| #{fname}"
        end
      end
    end
    
    # track completion in batch data
    results[:completed_at] = Time.now
    update_batch_info results, options
  end # perform
end
