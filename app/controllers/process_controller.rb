class ProcessController < ApplicationController
  GROUP_EPP = 10 # entries per page when using group order
  JOBS = %w[ clear_job refresh preview group ].freeze

  before_action :check_archive_file,
    only: %i[ show_externally  prepare_archive  delete_archive  sample_images  compare_add ]

  before_action :check_archive_folder,
    only: %i[ edit  set_property  finalize_volume  show_image edit_cover
              rename_images  rename_file inspect_folder  add_files
              delete_archive_cwd  delete_archive_files  split_archive ]

  # list processable files
  def index
    # run requested job
    if JOBS.include?(params[:job])
      case params[:job]
        when 'clear_job'.freeze
          ProcessIndexRefreshJob.cleanup_files
        else
          job = "ProcessIndex#{params[:job].capitalize}Job".constantize
          job.lock_file!
          job.perform_later order: session['process.index.sort_by'],
            term: params[:term], page: params[:page], id: params[:id]
      end

      return redirect_to(action: :index, sort_by: session['process.index.sort_by'], term: params[:term], page: params[:page])
    end

    # save and keep previous sort order
    if params[:sort_by].present?
      session['process.index.sort_by'] = params[:sort_by]
    elsif session['process.index.sort_by'].present?
      return redirect_to(action: :index, sort_by: session['process.index.sort_by'], page: params[:page], term: params[:term])
    end

    if ProcessIndexRefreshJob.lock_file? # jobs: Refresh, Preview
      @refreshing       = true
      @refresh_progress = ProcessIndexRefreshJob.progress.to_s.split ' | '.freeze
    else
      @group_sort = session['process.index.sort_by'].to_s.starts_with?('group')

      # read "to_sort" file list
      @files = ProcessIndexRefreshJob.
        entries(order: session['process.index.sort_by']).
        page(params[:page]).per(@group_sort ? GROUP_EPP : Setting[:process_epp].to_i)
      @files = @files.search(params[:term]) if params[:term].present?

      # read "sorting" file list
      files_glob = File.join Setting['dir.sorting'], '*', 'info.yml'
      @preparing = Dir[files_glob].map{|f|
        tot_size = Dir.glob("#{File.dirname f}/contents/**/*").
          map{|f| f.ends_with?('/file.zip') ? 0 : File.size(f) rescue 0 }.sum
        YAML.unsafe_load_file(f).merge tot_size: tot_size
      }.sort_by_method('[]', :relative_path)
      @preparing_paths = @preparing.map{|i| i[:relative_path] }
    end

    files_glob = File.join Setting['dir.sorting'], 'batch_*.yml'
    @batches = Dir[files_glob].map{|f|
      { hash: File.basename(f).sub(/batch_(.+).yml/, '\1'), time: File.ctime(f) }
    }.sort_by_method('[]', :time)
  end # index

  # prepare ZIP working folder and redirects to edit
  def prepare_archive
    hash = ProcessArchiveDecompressJob.prepare_and_perform @fname

    hash == :invalid_zip ?
      redirect_to(process_index_path, alert: "invalid MIME type: not a ZIP file!") :
      redirect_to(edit_process_path id: hash)
  end # prepare_archive

  # extract some random images from the ZIP file
  def sample_images
    @images = []

    Zip::File.open(@fname) do |zip|
      zip.image_entries.shuffle[0..5].sort_by_method(:name).each do |e|
        thumb = Vips::Image.webp_cropped_thumb e.get_input_stream.read,
          width: 480, height: 960, padding: false
        @images << { name: e.name, data: Base64.encode64(thumb[:image].webpsave_buffer).chomp }
      end
    end
  end # sample_images

  # prepare working YML file and redirects to batch action
  def prepare_batch
    if params[:file_ids].to_a.any?
      hash = ProcessBatchJob.prepare params[:file_ids]
      redirect_to batch_process_path(id: hash)
    else
      redirect_to process_index_path, alert: "no files selected!"
    end
  end # prepare_batch

  # start/monitor batch processing files
  def batch
    info_path = ProcessBatchJob.info_path params[:id]
    return redirect_to(process_index_path, alert: "batch not found!") unless File.exist?(info_path)

    @info = YAML.unsafe_load_file info_path

    if request.delete?
      if params[:undo]
        # halt batch processing
        @info.delete :started_at
        File.atomic_write(info_path){|f| f.puts @info.to_yaml }
        return redirect_to(batch_process_path(id: params[:id]), notice: "batch processing halted")
      elsif params[:remove].present?
        # remove the entry from batch data file
        %i[ files thumbs titles ].each{|k| @info[k].delete params[:remove] }
        @info[:filenames] -= [params[:remove]]
        File.atomic_write(info_path){|f| f.puts @info.to_yaml }
        row = [0, params[:row].to_i - 1].max
        return redirect_to(batch_process_path(id: params[:id], anchor: "row_#{row}"), notice: "entry removed: [#{params[:remove]}]")
      else
        # remove entire batch data file
        File.unlink info_path
        return redirect_to(process_index_path, notice: "batch deleted: [#{params[:id][0..10]}...]")
      end
    end # DELETE

    if request.post?
      if params[:name].present?
        # change the entry destination title
        if @info[:titles][params[:path]]
          @info[:titles][params[:path]] = params[:name].strip
          File.atomic_write(info_path){|f| f.puts @info.to_yaml }
          return render(json: {result: 'ok'})
        else
          return render(json: {result: 'err', msg: "path not found [#{params[:path]}]"})
        end
      end
    end # POST

    # update options
    if params[:options]
      @info[:options] = { hash: params[:id] }

      dj = Doujin.find_by(id: params[:options][:doujin_id].to_i)
      @info[:options][:doujin_id] = dj.id if dj

      @info[:options][:score] = params[:options][:score].present? ? params[:options][:score].to_i : nil

      %i[ col cens overwrite ].each do |k|
        @info[:options][k] = params[:options][k].present? ? (params[:options][k] == 'true') : nil
      end
      %i[ lang mt batch_method ].each do |k|
        @info[:options][k] = params[:options][k].present? ? params[:options][k] : nil
      end

      File.atomic_write(info_path){|f| f.puts @info.to_yaml }

      if params[:button] == 'start'
        @info[:started_at] = Time.now
        File.atomic_write(info_path){|f| f.puts @info.to_yaml }

        # list of files to keep cover auto cropped
        @info[:options][:keep_cover] = @info[:thumbs].
          map{|name, data| File.join(Setting['dir.to_sort'], name) if data[:keep_cover] }.compact

        # hash: { full_path => title }
        files = @info[:files].keys.
          inject({}){|h, f| h.merge File.join(Setting['dir.to_sort'], f) => @info[:titles][f] }

        ProcessBatchJob.perform_later dj&.id, files, @info[:options]

        flash[:notice] = 'batch processing started'
      end

      return redirect_to(batch_process_path(id: params[:id]))
    end

    if params[:keep_cover].present? && @info[:thumbs][params[:keep_cover]]
      @info[:thumbs][params[:keep_cover]][:keep_cover] = !@info[:thumbs][params[:keep_cover]][:keep_cover]
      File.atomic_write(info_path){|f| f.puts @info.to_yaml }
      return redirect_to(batch_process_path(id: params[:id], anchor: Digest::MD5.hexdigest(params[:keep_cover])))
    end

    respond_to do |format|
      format.html
      format.json {
        ExternalProgramRunner.run params[:run],
          @info[:files].keys, chdir: Setting['dir.to_sort']
        render json: {ris: :done}
      }#json
    end
  end # batch

  # delete selected files
  def batch_delete
    if params[:file_ids].to_a.any?
      params[:file_ids].each{|id| ProcessIndexRefreshJob.rm_entry id, track: true, rm_zip: true }

      redirect_to process_index_path(term: params[:term]), notice: "#{params[:file_ids].size} files deleted"
    else
      redirect_to process_index_path(term: params[:term]), alert: "no files selected!"
    end
  end # batch_delete

  # process multiple files into a single folder
  def batch_merge
    hash = ProcessArchiveDecompressJob.prepare_and_perform params[:file_ids]

    hash == :invalid_zip ?
      redirect_to(process_index_path, alert: "invalid MIME type: not a ZIP file!") :
      redirect_to(edit_process_path id: hash)
  end # batch_merge

  def delete_archive
    ProcessArchiveDecompressJob.rm_entry path: params[:path]
    ProcessIndexRefreshJob.rm_entry params[:path], track: true, rm_zip: true

    row = [0, params[:row].to_i - 1].max
    redirect_to(process_index_path(page: params[:page], term: params[:term], anchor: "row_#{row}"), notice: "file deleted: [#{params[:path]}]")
  end # delete_archive

  def delete_archive_cwd
    @info = YAML.unsafe_load_file(File.join @dname, 'info.yml')

    if params[:archive_too] == 'true' || @info[:dummy]
      if @info[:relative_path].one?
        ProcessIndexRefreshJob.rm_entry @info[:relative_path].first, track: @info[:db_doujin_id].blank?, rm_zip: true
      else
        # always track merged entries
        doujin_id = @info[:db_doujin_id].to_i if @info[:db_doujin_id].to_i > 0
        @info[:relative_path].
          each{|rp| ProcessIndexRefreshJob.rm_entry rp, track: true, rm_zip: true, merged: true, doujin_id: doujin_id }
      end
    end

    ProcessArchiveDecompressJob.rm_entry folder: @dname

    CoverMatchingJob.rm_results_file @info[:cover_hash]

    msg   = params[:archive_too] == 'true' ? "archive and folder deleted:" : "folder deleted for"
    title = @info[:relative_path].one?     ? @info[:relative_path].first   : @info[:title]
    redirect_to process_index_path, notice: "#{msg} [#{title}] in [#{params[:id][0..10]}...]"
  end # delete_archive_cwd

  def split_archive
    num_splits = ProcessArchiveSplitJob.perform_now @dname, params[:path]
    redirect_to process_index_path, notice: "#{num_splits} splits created"
  end # split_archive

  def delete_archive_files
    @info = YAML.unsafe_load_file(File.join @dname, 'info.yml')

    params[:path] = [ params[:path] ] unless params[:path].is_a?(Array)

    params[:path].each do |path|
      if idx = @info[:files].index{|i| i[:src_path] == path }
        @info[:files].delete_at idx
        FileUtils.rm_f File.join(@dname, 'contents', path)
      else
        if idx = @info[:images].index{|i| i[:src_path] == path }
          @info[:images].delete_at idx
          FileUtils.rm_f File.join(@dname, 'contents', path)
        end
      end
    end

    ProcessArchiveDecompressJob.crop_landscape_cover @dname, @info, @info[:landscape_cover_method]

    ArchiveUtils.check_filename_collisions @info

    File.open(File.join(@dname, 'info.yml'), 'w'){|f| f.puts @info.to_yaml }

    # redirect to next tabs when deleting images from "Pics" tab
    if params[:tab] == 'images'
      params[:tab] = @info[:dest_folder].present? ? :move : :ident
    end

    redirect_to edit_process_path(id: params[:id], tab: params[:tab]),
      notice: "#{params[:path].size} file/s deleted"
  end # delete_archive_files

  def set_property
    @info  = YAML.unsafe_load_file(File.join @dname, 'info.yml')
    @perc  = File.read(File.join @dname, 'completion.perc').to_f rescue 0.0 unless @info[:prepared_at]
    info_changed = false
    redir_anchor = nil

    # toggle associated author/circle ID
    %w[ author circle ].each do |k|
      key = "#{k}_ids".to_sym
      @info[key] ||= []
      tmp_id = params["#{k}_id".to_sym].to_i

      if tmp_id > 0
        method = @info[key].to_a.include?(tmp_id) ? :delete : :push
        @info[key].send method, tmp_id
        # remove destination if deleting it
        is_same_dj = "#{@info[:doujin_dest_type]}-#{@info[:doujin_dest_id]}" == "#{k}-#{tmp_id}"
        @info[:doujin_dest_id] = nil if method == :delete && is_same_dj
        info_changed = true
      end
    end

    # set destination author/circle when only one ID is present
    if    @info[:author_ids].size == 1 && @info[:circle_ids].size == 0
      params[:doujin_dest_id] = "author-#{@info[:author_ids].first}"
    elsif @info[:author_ids].size == 0 && @info[:circle_ids].size == 1
      params[:doujin_dest_id] = "circle-#{@info[:circle_ids].first}"
    end

    # select a destination author/circle
    if params[:doujin_dest_id] && params[:doujin_dest_id] != "#{@info[:doujin_dest_type]}-#{@info[:doujin_dest_id]}"
      # store type and ID
      @info[:doujin_dest_type], @info[:doujin_dest_id] = params[:doujin_dest_id].split('-')
      # set destination folder to subject romaji name
      if @info[:file_type] == 'doujin'
        subject = @info[:doujin_dest_type].capitalize.constantize.find_by(id: @info[:doujin_dest_id])
        @info[:dest_folder] = (subject.name_romaji.present? ? subject.name_romaji : subject.name_kakasi).downcase.strip
      else
        @info[:dest_folder] = ''
      end
      info_changed = true
    end

    # set "artbook" as default media type for "artbook" category
    if params[:file_type] == 'artbook' && params[:file_type] != @info[:file_type]
      params[:media_type] = 'artbook'
    end

    %i[
      dupe_search
      file_type
      dest_folder
      subfolder
      dest_title
      dest_title_romaji
      dest_title_eng
      dest_filename
      reading_direction
      language
      censored
      colorized
      media_type
      notes
    ].each do |k|
      if params[k] && params[k] != @info[k]
        @info[k] = params[k].strip.gsub(/ +/, ' ')
        info_changed = true
      end
    end

    @info[:dest_filename] = @info[:orig_dest_filename] if @info[:dest_filename].blank?

    # toggle overwrite of file in the collection
    if params[:overwrite] && (params[:overwrite].to_i == 1) != @info[:overwrite]
      @info[:overwrite] = params[:overwrite].to_i == 1
      info_changed = true
    end

    # set doujin scoring
    if params[:score] && params[:score].to_i != @info[:score]
      @info[:score] = params[:score].to_i
      info_changed = true
    end

    if @info[:landscape_cover] && params[:cover_crop_method] && params[:cover_crop_method] != @info[:cover_crop_method]
      @info[:cover_crop_method] = params[:cover_crop_method]
      ProcessArchiveDecompressJob.crop_landscape_cover @dname, @info, params[:cover_crop_method].to_sym
      redir_anchor = :cover
      info_changed = true
    end

    File.open(File.join(@dname, 'info.yml'), 'w'){|f| f.puts @info.to_yaml } if info_changed

    if params[:button] == 'finalize'
      redirect_to finalize_volume_process_path(id: params[:id], confirm: true)
    else
      redirect_to edit_process_path(id: params[:id], tab: params[:tab], term: params[:term], anchor: redir_anchor)
    end
  end # set_property

  # manage archive operations (sanitize filenames, delete extra images, identify author)
  def edit
    params[:tab] = 'dupes' unless %w[ dupes files images ident move ].include?(params[:tab])

    @info  = YAML.unsafe_load_file(File.join @dname, 'info.yml')
    @perc  = File.read(File.join @dname, 'completion.perc').to_f rescue 0.0 unless @info[:prepared_at]
    @fname = File.basename(@info[:relative_path].one? ? @info[:relative_path].first.to_s : @info[:title].to_s)

    return render unless @info[:prepared_at]

    # clone relations from another doujin
    if params[:ident_from] && (d = Doujin.find_by id: params[:ident_from])
      @info[:author_ids ], @info[:circle_ids] = d.author_ids, d.circle_ids
      @info[:dest_folder], @info[:subfolder ] = d.file_folder.to_s.split(File::SEPARATOR)
      @info[:doujin_dest_type ] = d.category
      @info[:dest_title       ] = d.name
      @info[:dest_title_romaji] = d.name_romaji if d.name_romaji.present?
      @info[:dest_title_eng   ] = d.name_eng    if d.name_eng   .present?
      @info[:dest_filename    ] = d.file_name
      @info[:score            ] = d.score
      File.atomic_write(File.join @dname, 'info.yml'){|f| f.puts @info.to_yaml }
      return redirect_to({tab: :ident}, notice: "relations and folders cloned")
    end

    # run cover image hash matching for the first time
    params[:rematch_cover] = true if @info[:cover_hash].blank?

    if %w[ dupes move ].include?(params[:tab])
      # current file stats
      f_size = helpers.number_to_human_size @info[:file_size]
      f_imgs = @info[:images].size
      @cur_info = "#{f_imgs} pics/#{f_size}"
    end

    case params[:tab]
      when 'dupes'
        # refresh cover matching results
        if params[:rematch_cover] && @info[:images].any?
          # update @info rehashing cover and run a new search
          @info = @info.slice! :cover_hash, :cover_results, :cover_status # reset @info
          cover_path = ProcessArchiveDecompressJob.cover_path @dname, @info
          @info[:cover_hash] = CoverMatchingJob.hash_image cover_path
          File.open(File.join(@dname, 'info.yml'), 'w'){|f| f.puts @info.to_yaml }
          CoverMatchingJob.perform_now @info[:cover_hash]
        end

        @dupes, @dupes_deleted = [], []

        # search dupes by cover similarity
        # check matching status/results
        if @info[:cover_hash].present? && !@info[:cover_results].is_a?(Hash)
          cover_matching = CoverMatchingJob.results @info[:cover_hash]
          if cover_matching.is_a?(Hash)
            @info[:cover_results        ] = cover_matching[:results        ]
            @info[:cover_results_deleted] = cover_matching[:results_deleted]
            @info[:cover_status         ] = cover_matching[:status]
            @info[:dupes_found] = cover_matching[:results].try(:any?) || cover_matching[:results_deleted].try(:any?)
            File.open(File.join(@dname, 'info.yml'), 'w'){|f| f.puts @info.to_yaml }
          else
            @info[:cover_status] = cover_matching
          end
        end
        # find dupes and set similarity percent
        if @info[:cover_results].is_a?(Hash)
          @dupes += @info[:cover_results].sort_by_value(reverse: true).map{|id, perc|
            next unless d = Doujin.find_by(id: id)
            d.cover_similarity = perc
            d
          }.compact
        end
        # find deleted dupes and set similarity percent
        if @info[:cover_results_deleted].is_a?(Hash)
          @dupes_deleted += @info[:cover_results_deleted].sort_by_value(reverse: true).map{|id, perc|
            next unless d = DeletedDoujin.find_by(id: id)
            d.cover_similarity = perc
            d
          }.compact
        end

        @info[:dupe_search] ||= @fname.tokenize_doujin_filename(title_only: true).join ' '
        params[:dupe_search] ||= @info[:dupe_search]
        # search dupes by filename
        @dupes += Doujin.
          where.not(id: @dupes.map(&:id)).
          search(params[:dupe_search], relations: false).
          order(:name_orig).limit(30).to_a
        # search dupes by filename in deleted doujinshi
        @dupes_deleted += DeletedDoujin.
          where.not(id: @dupes_deleted.map(&:id)).
          search(params[:dupe_search]).
          order(:name).limit(10).to_a

      when 'ident'
        # list possible dest folders
        @dest_folders = []
        case @info[:file_type]
          when 'doujin'
            if @info[:doujin_dest_type]
              repo = File.join(Setting['dir.sorted'], @info[:doujin_dest_type]).to_s
              @dest_folders = Dir[File.join repo, '*'].select{|i| File.directory? i }.
                map{|i| Pathname.new(i).relative_path_from(repo).to_s }.sort.unshift('-custom name-')
            end
          when 'magazine', 'artbook'
            repo = File.join(Setting['dir.sorted'], @info[:file_type]).to_s
            @dest_folders = Dir[File.join repo, '*'].select{|i| File.directory? i }.
              map{|i| Pathname.new(i).relative_path_from(repo).to_s }.sort.unshift('-custom name-')
        end

        # lists of currently associated authors/circles
        @associated_authors = Author.where(id: @info[:author_ids]).order("LOWER(name), id DESC")
        @associated_circles = Circle.where(id: @info[:circle_ids]).order("LOWER(name), id DESC")

        # filename analisys
        @name = File.basename(@fname).parse_doujin_filename
        # single term search
        params[:term] = @name[:ac_explicit][0] || @name[:ac_implicit][0] if params[:term].blank?
        @authors = Author.search_by_name params[:term], limit: 50
        @circles = Circle.search_by_name params[:term], limit: 50

      when 'move'
        if @info[:file_type] == 'doujin' && (@info[:doujin_dest_type].blank? || @info[:dest_folder].blank?)
          return redirect_to(edit_process_path(id: params[:id], tab: 'ident'), alert: "select the primary association and destination folder")
        end

        # list possible dest subfolders
        @subfolders = ['-custom name-']
        cat  = @info[:file_type] == 'doujin' ? @info[:doujin_dest_type] : @info[:file_type]
        repo = File.join(Setting['dir.sorted'], cat, @info[:dest_folder]).to_s
        @subfolders += Dir[File.join repo, '*'].select{|i| File.directory? i }.
          map{|i| Pathname.new(i).relative_path_from(repo).to_s }.
          sort if File.exist?(repo)

        # find similar names to suggest
        search_terms = @info[:dest_filename].tokenize_doujin_filename(rm_num: true).join ' '
        if search_terms.size > 6
          sql_name = "COALESCE(NULLIF(name_romaji, ''), NULLIF(name_kakasi, ''))"
          @suggestions = Doujin.
            where(category: cat).
            where("file_folder LIKE ?", "#{@info[:dest_folder]}%").
            search(search_terms, relations: false).
            reselect(Arel.sql "#{sql_name} AS name").
            limit(50).map(&:name)
        end

        # check if file already exists on disk/collection
        collection_file_path = Doujin.dest_path_by_process_params(@info, full_path: true)
        if File.exist?(collection_file_path)
          doujin = Doujin.find_by_process_params(@info)

          c_size = helpers.number_to_human_size File.size(collection_file_path)
          c_imgs = doujin.try(:num_images) || 'N.D.'
          f_size = helpers.number_to_human_size @info[:file_size]
          f_imgs = @info[:images].size

          @collision_info = { collection: "#{c_imgs} pics/#{c_size}", current: "#{f_imgs} pics/#{f_size}", doujin: doujin }
        end
    end
  end # edit

  def rename_images
    @info = YAML.unsafe_load_file(File.join @dname, 'info.yml')

    begin
      ZipImagesRenamer.rename @info[:images], params[:rename_with], params

      @info[:images] = @info[:images].sort_by_method('[]', :dst_path)

      @info[:ren_images_method      ] = params[:rename_with]
      @info[:images_last_regexp     ] = params[:rename_regexp]
      @info[:images_last_regexp_repl] = params[:rename_regexp_repl]

      ArchiveUtils.check_filename_collisions @info

      ProcessArchiveDecompressJob.crop_landscape_cover @dname, @info, @info[:landscape_cover_method]

      File.open(File.join(@dname, 'info.yml'), 'w'){|f| f.puts @info.to_yaml }

      redirect_to edit_process_path(id: params[:id], tab: params[:tab])
    rescue
      redirect_to(edit_process_path(id: params[:id], tab: params[:tab]), alert: $!.to_s)
    end
  end # rename_images

  def rename_file
    @info = YAML.unsafe_load_file(File.join @dname, 'info.yml')

    return render(json: {result: 'err', msg: "filename cannot be empty!" }) if params[:name].blank?

    if el = @info[:files].detect{|i| i[:src_path] == params[:path] }
      el[:dst_path] = params[:name].to_s.strip
      @info[:files] = @info[:files].sort_by_method('[]', :dst_path)
    elsif el = @info[:images].detect{|i| i[:src_path] == params[:path] }
      el[:dst_path] = params[:name].to_s.strip
      @info[:images] = @info[:images].sort_by_method('[]', :dst_path)
    end

    ArchiveUtils.check_filename_collisions @info

    if el
      ProcessArchiveDecompressJob.crop_landscape_cover @dname, @info, @info[:landscape_cover_method]

      File.open(File.join(@dname, 'info.yml'), 'w'){|f| f.puts @info.to_yaml }
      render(json: {result: 'ok'})
    else
      render(json: {result: 'err', msg: "image not found [#{params[:name]}]" })
    end
  end # rename_file

  def pd_notes
    ProcessableDoujin.find_by(id: params[:id])&.update(notes: params[:text].to_s[0...255].strip) ?
      render(json: {result: 'ok'}) :
      render(json: {result: 'err', msg: "item not found" })
  end # pd_notes

  def show_image
    sub_path = File.expand_path(params[:path], '/')[1..-1] # sanitize input
    send_file File.join(@dname, 'contents', sub_path),
      disposition: :inline, type: Marcel::MimeType.for(name: params[:path])
  end # show_image

  # rezip archive, add metadata, move/register in collection, cleaup WIP folder
  def finalize_volume
    @info = YAML.unsafe_load_file(File.join @dname, 'info.yml')
    @fname = File.basename(@info[:relative_path].one? ? @info[:relative_path].first.to_s : @info[:title].to_s)
    perc_file = File.join(@dname, 'finalize.perc')

    if @info[:images].empty?
      return redirect_to(edit_process_path(id: params[:id], tab: 'move'), alert: "no images present!")
    end

    unless @info[:dest_filename].to_s.end_with?('.zip')
      return redirect_to(edit_process_path(id: params[:id], tab: 'move'), alert: "destination filename not ending with \".zip\"")
    end

    if @info[:dest_folder].blank? && @info[:file_type] != 'artbook'
      return redirect_to(edit_process_path(id: params[:id], tab: 'ident'), alert: "empty destination folder")
    end

    unless @info[:dest_filename].present?
      return redirect_to(edit_process_path(id: params[:id], tab: 'move'), alert: "empty destination filename")
    end

    if !File.exist?(perc_file) && @info[:overwrite] != true && @info[:db_doujin_id].nil? &&
       File.exist?(Doujin.dest_path_by_process_params(@info, full_path: true))
      return redirect_to(edit_process_path(id: params[:id], tab: 'move'), alert: "file already exists in collection")
    end

    if request.post? || params[:confirm] == 'true' # perform actions only via POST or param
      if params[:undo] && File.exist?(perc_file)
        File.unlink(perc_file)
        fname = "#{@info[:collection_full_path]}.NEW"
        File.unlink(fname) if File.exist?(fname)
        return redirect_to(edit_process_path(id: params[:id]), notice: "finalize processing halted")
      end

      unless File.exist?(perc_file)
        FileUtils.touch perc_file
        ProcessArchiveCompressJob.perform_later @dname
        return redirect_to(finalize_volume_process_path(id: params[:id]))
      end
    end # if request.post?

    @perc = File.read(perc_file).to_f rescue 0.0
  end # finalize_volume

  def show_externally
    respond_to do |format|
      format.json {
        ExternalProgramRunner.run params[:run], @fname
        render json: {ris: :done}
      }#json
    end
  end # show_externally

  def edit_cover
    @info = YAML.unsafe_load_file(File.join @dname, 'info.yml')

    respond_to do |format|
      format.html {
        case params[:run]
          when 'refresh'
            ProcessArchiveDecompressJob.refresh_cover_thumb @dname, @info, save_info: true

          when 'rotate'
            ProcessArchiveDecompressJob.duplicate_cover @dname, @info, save_info: true
            ProcessArchiveDecompressJob.rotate_cover    @dname, @info, dir: params[:dir], save_info: true
        end

        redirect_to edit_process_path(id: params[:id], tab: params[:tab])
      }#html
      format.json {
        case params[:run]
          when 'duplicate_edit'
            ProcessArchiveDecompressJob.duplicate_cover @dname, @info, save_info: true

            # open image editor
            fname = File.join @dname, 'contents', @info[:images].first[:src_path]
            ExternalProgramRunner.run 'image_editor', fname

          else
            return render(json: {ris: :noop})
        end

        render json: {ris: :done}
      }#json
    end
  end # edit_cover

  def add_files
    @info = YAML.unsafe_load_file(File.join @dname, 'info.yml')

    # inject uploaded files
    params[:files]&.
      sort_by(&:original_filename)&.
      each{|f| ProcessArchiveDecompressJob.inject_file f.original_filename, f.to_path, @dname, info: @info }

    # inject local files
    last_name = @info[:images].last.try('[]', :dst_path)
    last_name = File.basename last_name, File.extname(last_name)
    params[:paths]&.sort&.each do |p|
      name = "#{last_name.next!}#{File.extname p}"
      ProcessArchiveDecompressJob.inject_file name, p, @dname, info: @info
    end

    ArchiveUtils.check_filename_collisions @info

    # update info
    File.open(File.join(@dname, 'info.yml'), 'w'){|f| f.puts @info.to_yaml }

    num_injected = params[:files]&.size.to_i + params[:paths]&.size.to_i
    redirect_to edit_process_path(id: params[:id], tab: params[:tab]),
      notice: "#{num_injected} file/s injected"
  end # add_files

  def inspect_folder
    respond_to do |format|
      format.json {
        ExternalProgramRunner.run params[:run], @dname
        render json: {ris: :done}
      }#json
    end
  end # inspect_folder

  def compare_add
    DoujinCompareJob.perform_now rel_path: params[:path], full_path: @fname, mode: params[:mode]
    redirect_to compare_doujinshi_path
  end # compare_add

  def compare_remove
    DoujinCompareJob.remove params[:idx]
    redirect_to(params[:idx] != 'all'.freeze ? compare_doujinshi_path : root_path)
  end # compare_remove

  def process_later
    ProcessableDoujin.find_by(id: params[:id])&.process_later
    redirect_to process_index_path, notice: "file moved in [#{DJ_DIR_PROCESS_LATER}] folder"
  end # process_later

  def group_rm
    ProcessIndexGroupJob.rm_entry params[:id]

    if request.xhr?
      render json: {id: params[:id].to_i}
    else
      row = [0, params[:row].to_i - 1].max
      redirect_to process_index_path(page: params[:page], anchor: "row_#{row}", sort_by: params[:sort_by]),
        notice: "file removed from group ##{params[:parent_id]}"
    end
  end # group_rm

  def clear
    msg = case params[:what]
      when 'samples'
        ProcessIndexPreviewJob.rm_previews
        'sample images cleared'
      when 'eh_cookies'
        Ws::EHentai.clear_cookies
        'EH coockies cleared'
      else
        'nothing to clear'.freeze
    end

    redirect_to process_index_path, notice: msg
  end # process_later


  private # ____________________________________________________________________


  def check_archive_file
    @fname = File.expand_path File.join(Setting['dir.to_sort'], params[:path])

    if !File.exist?(@fname) && params[:action] != 'delete_archive'
      return redirect_to(process_index_path, alert: "file not found!")
    end

    unless @fname.start_with?(Setting['dir.to_sort'])
      redirect_to process_index_path, alert: "file outside of working directory!"
    end
  end # check_archive_file

  def check_archive_folder
    @dname = File.expand_path File.join(Setting['dir.sorting'], params[:id])

    return redirect_to(process_index_path, alert: "folder not found!") unless File.exist?(@dname)

    unless @dname.start_with?(Setting['dir.sorting'])
      redirect_to process_index_path, alert: "folder outside of working directory!"
    end
  end # check_archive_folder
end
