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
        files:       names.inject({}){|h, n| h.merge n => nil }, # {name: array_of_filesname}
        prepared_at: nil,
        options: {
          # autoselect the last added doujin ID
          doujin_id: Doujin.order(created_at: :desc).limit(1).pluck(:id).first,
        },
      }.to_yaml)
    end

    # extract files names and covers for user inspection before processing
    ProcessBatchInspectJob.perform_later hash

    hash
  end # self.prepare

  def perform(doujin_id, files, options = {})
    dj = Doujin.find_by id: doujin_id

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

      Rails.logger.error ColorizedString['ERROR'].black.on_red + ColorizedString[" #{msg}"].red
    end # add_error

    results = {}

    # fill results with each files to process
    files.each do |dj_fname, dj_title|
      Rails.logger.info '-'*70
      Rails.logger.info "FILE: #{dj_fname}"

      dj_title = "#{dj_title}.zip" unless dj_title.downcase.end_with?('.zip')

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

      hash = ProcessArchiveDecompressJob.prepare_and_perform \
        fname, perform_when: :now, title: dj_title

      if hash == :invalid_zip
        add_error results, fname, 'not a ZIP file', options
        next
      end

      dname = File.expand_path File.join(Setting['dir.sorting'], hash)
      info_fname = File.join dname, 'info.yml'
      info  = YAML.unsafe_load_file info_fname
      Rails.logger.info "HASH: #{hash}"

      if info[:images].empty?
        add_error results, fname, 'no images found', options
        next
      end

      Rails.logger.info "[DST]     [SRC]"
      info[:images].each{|i| Rails.logger.info "#{i[:dst_path]}  #{i[:src_path]}" }
      if info[:files].any?
        Rails.logger.info "--------  --------------------"
        info[:files].each{|i| Rails.logger.info "#{i[:dst_path]}  #{i[:src_path]}" }
      end

      if dj
        # copy data from source doujin
        info[:file_type    ] = dj.category
        if %w[ author circle ].include?(dj.category)
          info[:file_type       ] = 'doujin'
          info[:doujin_dest_type] = dj.category
        end
        info[:dest_folder], info[:subfolder] = dj.file_folder.split(File::SEPARATOR)
        info[:reading_direction] = dj.reading_direction
        info[:author_ids   ] = dj.author_ids
        info[:circle_ids   ] = dj.circle_ids
      end

      # set data from given options
      info[:dest_title   ] = options[:dest_title] if options[:dest_title].present?
      info[:score        ] = options[:score] if options[:score]

      info[:language     ] = options[:lang] unless options[:lang].nil? # dj.language
      info[:censored     ] = options[:cens] unless options[:cens].nil? # dj.censored
      info[:colorized    ] = options[:col ] unless options[:col ].nil? # dj.colorized
      info[:media_type   ] = options[:mt  ] unless options[:mt  ].nil? # dj.media_type
      info[:overwrite    ] = true if options[:overwrite]

      info[:dest_filename] = options[:dest_filename] if options[:dest_filename]
      info[:dest_filename] = File.basename(fname).sub(/ *\.zip$/i, '.zip') if options[:keep_filename]
      File.open(info_fname, 'w'){|f| f.puts info.to_yaml }

      # run cover image hash matching
      cover_path = ProcessArchiveDecompressJob.cover_path dname, info
      info[:cover_hash] = CoverMatchingJob.hash_image(cover_path, hash_only: true)
      CoverMatchingJob.perform_now info[:cover_hash][:phash], info[:cover_hash][:sdhash]
      cover_matching = CoverMatchingJob.results info[:cover_hash][:phash]
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

      if options[:batch_method] == 'process'
        perc_file = File.join(dname, 'finalize.perc')
        unless File.exist?(perc_file)
          FileUtils.touch perc_file
          ProcessArchiveCompressJob.perform_now dname

          info = YAML.unsafe_load_file info_fname
          if info[:finalize_error].blank?
            Rails.logger.info "DjID: #{info[:db_doujin_id]}"
            results[fname][:id] = info[:db_doujin_id].to_i
            # remove WIP folder, index entry, file on disk
            FileUtils.rm_rf dname, secure: true
            ProcessIndexRefreshJob.rm_entry info[:relative_path], rm_zip: true
          else
            add_error results, fname, 'processing errors', options # [#{info[:finalize_error]}]
            next
          end
        end
      else
        add_error results, fname, 'prepared', options
      end

      update_batch_info results, options
    end # each filename

    # print final report
    if files.many?
      Rails.logger.info '~~~~~ o ~~~~~ o ~~~~~ o ~~~~~ o ~~~~~ o ~~~~~ o ~~~~~ o ~~~~~ o ~~~~~'
      base_dir, max_len = Setting['dir.to_sort'], 18
      results.keys.sort.partition{|k| results[k][:id] }.flatten.each do |k|
        fname = Pathname.new(k).relative_path_from(base_dir).to_s
        if results[k][:id]
          msg = ColorizedString['OK'].white.on_green +
                ColorizedString[" #{results[k][:id].to_s.ljust max_len}"].green
          Rails.logger.info "#{msg}| #{fname}"
        end

        results[k][:errors].to_a.each do |msg|
          msg = ColorizedString['KO'].black.on_red +
                ColorizedString[" #{msg.ljust max_len}"].red
          Rails.logger.info "#{msg}| #{fname}"
        end
      end
    end

    # track completion in batch data
    results[:completed_at] = Time.now
    update_batch_info results, options
  end # perform
end
