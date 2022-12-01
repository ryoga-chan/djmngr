class ProcessController < ApplicationController
  INDEX_MAX_ENTRIES = 100

  before_action :check_archive_file  , only: [
    :show_externally, :prepare_archive, :delete_archive
  ]
  before_action :check_archive_folder, only: [
    :edit, :set_property, :finalize_volume,
    :show_image, :rename_images, :rename_file,
    :delete_archive_cwd, :delete_archive_files,
  ]

  # list processable files
  def index
    # create archive folders
    folders  = [ Setting['dir.to_sort'], Setting['dir.sorting'] ]
    folders += %w{ author circle magazine artbook }.map{|d| File.join(Setting['dir.sorted'], d).to_s }
    folders << File.join(Setting['dir.to_sort'], 'reprocess')
    folders.each{|f| FileUtils.mkdir_p f }
    
    # create "to_sort" file list
    if params[:refresh]
      ProcessIndexRefreshJob.lock_file!
      ProcessIndexRefreshJob.perform_later
      return redirect_to(action: :index)
    end

    if ProcessIndexRefreshJob.lock_file?
      @refreshing = true
    else
      # read "to_sort" file list
      @files = ProcessIndexRefreshJob.entries
      
      # read "sorting" file list
      files_glob = File.join Setting['dir.sorting'], '*', 'info.yml'
      @preparing = Dir[files_glob].map{|f|
        tot_size = Dir.glob("#{File.dirname f}/**/*").
          map{|f| f.ends_with?('/file.zip') ? 0 : File.size(f) }.sum
        YAML.load_file(f).merge tot_size: tot_size
      }.sort{|a,b| a[:relative_path] <=> b[:relative_path] }
      @preparing_paths = @preparing.map{|i| i[:relative_path] }
    end
  end # index
  
  # prepare ZIP working folder and redirects to edit
  def prepare_archive
    hash = ProcessArchiveDecompressJob.prepare_and_perform @fname
    
    hash == :invalid_zip ?
      redirect_to(process_index_path, alert: "invalid MIME type: not a ZIP file!") :
      redirect_to(edit_process_path id: hash)
  end # prepare_archive
  
  def delete_archive
    # count images and other files
    file_counters = {num_images: 0, num_files: 0}
    Zip::File.open(@fname) do |zip|
      zip.entries.each do |e|
        next unless e.file?
        file_counters[e.name =~ ProcessArchiveDecompressJob::IMAGE_REGEXP ? :num_images : :num_files] += 1
      end
    end
    # track deletion
    name = params[:path].tr(File::SEPARATOR, ' ')
    DeletedDoujin.create file_counters.merge({
      name:             name,
      name_kakasi:      name.to_romaji,
      size:             File.size(@fname),
    })
    # remove file on disk
    File.unlink @fname
    return redirect_to(process_index_path, notice: "file deleted: [#{params[:path]}]")
  end # delete_archive
  
  def delete_archive_cwd
    @info = YAML.load_file(File.join @dname, 'info.yml')
    if params[:archive_too] == 'true'
      # track deletion unless stored in collection
      DeletedDoujin.create({
        name:             @info[:relative_path],
        name_kakasi:      @info[:relative_path].to_romaji,
        size:             @info[:file_size],
        num_images:       @info[:images].to_a.size,
        num_files:        @info[:files ].to_a.size,
      }) unless @info[:db_doujin_id].present?
      # remove file on disk
      File.unlink @info[:file_path]
      # update filelist
      ProcessIndexRefreshJob.rm_entry @info[:relative_path]
    end
    
    FileUtils.rm_rf @dname, secure: true
    
    CoverMatchingJob.rm_results_file info[:cover_hash]
    
    msg = params[:archive_too] == 'true' ? "archive and folder deleted:" : "folder deleted for"
    return redirect_to(process_index_path, notice: "#{msg} [#{@info[:relative_path]}] in [#{params[:id][0..10]}...]")
  end # delete_archive_cwd
  
  def delete_archive_files
    @info = YAML.load_file(File.join @dname, 'info.yml')
    
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
    
    File.open(File.join(@dname, 'info.yml'), 'w'){|f| f.puts @info.to_yaml }
    
    return redirect_to(edit_process_path(id: params[:id], tab: params[:tab]),
      notice: "#{params[:path].size} file/s deleted")
  end # delete_archive_files
  
  def set_property
    @info  = YAML.load_file(File.join @dname, 'info.yml')
    @perc  = File.read(File.join @dname, 'completion.perc').to_f rescue 0.0 unless @info[:prepared_at]
    @fname = File.basename(@info[:relative_path].to_s)
    info_changed = false

    # toggle associated author/circle ID
    %w{ author circle }.each do |k|
      tmp_id = params["#{k}_id".to_sym].to_i
      
      if tmp_id > 0
        key = "#{k}_ids".to_sym
        @info[key] ||= []
        method = @info[key].to_a.include?(tmp_id) ? :delete : :push
        @info[key].send method, tmp_id
        # remove destination if deleting it
        @info[:doujin_dest_id] = nil if method == :delete && @info[:doujin_dest_id] == "#{k}-#{tmp_id}"
        info_changed = true
      end
    end
    
    # select a main/destination author/circle
    if params[:doujin_dest_id] && params[:doujin_dest_id] != "#{@info[:doujin_dest_type]}-#{@info[:doujin_dest_id]}"
      # store type and ID
      @info[:doujin_dest_type], @info[:doujin_dest_id] = params[:doujin_dest_id].split('-')
      # set destination folder to subject romaji name
      subject = @info[:doujin_dest_type].capitalize.constantize.find_by(id: @info[:doujin_dest_id])
      @info[:dest_folder] = (subject.name_romaji || subject.name_kakasi).downcase.strip
      info_changed = true
    end
    
    %i{
      dupe_search
      file_type
      dest_folder
      subfolder
      dest_filename
      reading_direction
      language
      censored
      colorized
      notes
      cover_crop_method
    }.each do |k|
      if params[k] && params[k] != @info[k]
        @info[k] = params[k].strip
        info_changed = true
      end
    end
    
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
    
    if @info[:landscape_cover] && params[:cover_crop_method]
      ProcessArchiveDecompressJob.crop_landscape_cover @dname, @info, params[:cover_crop_method].to_sym
      info_changed = true
    end
    
    File.open(File.join(@dname, 'info.yml'), 'w'){|f| f.puts @info.to_yaml } if info_changed
    
    redirect_to edit_process_path(id: params[:id], tab: params[:tab], term: params[:term])
  end # set_property
  
  # manage archive operations (sanitize filenames, delete extra images, identify author)
  def edit
    params[:tab] = 'dupes' unless %w{ dupes files images ident move }.include?(params[:tab])
    
    @info  = YAML.load_file(File.join @dname, 'info.yml')
    @perc  = File.read(File.join @dname, 'completion.perc').to_f rescue 0.0 unless @info[:prepared_at]
    @fname = File.basename(@info[:relative_path].to_s)
    
    return render unless @info[:prepared_at]
    
    case params[:tab]
      when 'dupes'
        # refresh cover matching results
        if params[:rematch_cover]
          # update @info rehashing cover and run a new search
          @info = @info.slice! :cover_hash, :cover_results, :cover_status # reset @info
          cover_path = ProcessArchiveDecompressJob.cover_path @dname, @info
          @info[:cover_hash] = CoverMatchingJob.hash_image cover_path
          File.open(File.join(@dname, 'info.yml'), 'w'){|f| f.puts @info.to_yaml }
          CoverMatchingJob.perform_later @info[:cover_hash]
        end
        
        @dupes = []
      
        # search dupes by cover similarity
        # check matching status/results
        if @info[:cover_hash].present? && !@info[:cover_results].is_a?(Hash)
          cover_matching = CoverMatchingJob.results @info[:cover_hash]
          if cover_matching.is_a?(Hash)
            @info[:cover_results] = cover_matching[:results]
            @info[:cover_status ] = cover_matching[:status]
            File.open(File.join(@dname, 'info.yml'), 'w'){|f| f.puts @info.to_yaml }
          else
            @info[:cover_status] = cover_matching
          end
        end
        # find dupes and set similarity percent
        @dupes += @info[:cover_results].map do |id, perc|
          next unless d = Doujin.find_by(id: id)
          d.cover_similarity = perc
          d
        end if @info[:cover_results].is_a?(Hash)
        
        # search dupes by filename
        @info[:dupe_search] ||= @info[:relative_path].tokenize_doujin_filename.join ' '
        params[:dupe_search] ||= @info[:dupe_search]
        @dupes += Doujin. # NOTE: sqlite LIKE is case insensitive
          where("name_orig LIKE ?", "%#{params[:dupe_search].tr ' ', '%'}%").
          where.not(id: @dupes.map(&:id)).
          order(:name_orig).limit(10).to_a
        
        # current file stats
        f_size = helpers.number_to_human_size File.size(@info[:file_path])
        f_imgs = @info[:images].size
        @cur_info = "#{f_imgs} pics/#{f_size}"
      
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
        @name = File.basename(@info[:relative_path].to_s).parse_doujin_filename
        # single term search
        params[:term] = @name[:ac_explicit][0] || @name[:ac_implicit][0] if params[:term].blank?
        @authors = Author.search_by_name params[:term], limit: 50
        @circles = Circle.search_by_name params[:term], limit: 50
      
      when 'move'
        if @info[:file_type] == 'doujin' && @info[:doujin_dest_type].blank?
          return redirect_to(edit_process_path(id: params[:id], tab: 'ident'), alert: "choose the primary association")
        end
        
        # list possible dest subfolders
        @subfolders = ['-custom name-']
        cat  = @info[:file_type] == 'doujin' ? @info[:doujin_dest_type] : @info[:file_type]
        repo = File.join(Setting['dir.sorted'], cat, @info[:dest_folder]).to_s
        @subfolders += Dir[File.join repo, '*'].select{|i| File.directory? i }.
          map{|i| Pathname.new(i).relative_path_from(repo).to_s }.
          sort if File.exist?(repo)
        
        # find similar names to suggest
        search_terms = @info[:dest_filename].tokenize_doujin_filename(remove_numbers: true).join '%'
        if search_terms.size > 6
          sql_name = "COALESCE(NULLIF(name_romaji, ''), NULLIF(name_kakasi, ''))"
          # NOTE: sqlite LIKE is case insensitive
          @suggestions = Doujin.
            distinct.select(Arel.sql "#{sql_name} AS name").
            where(category: @info[:file_type]).
            where("name_romaji LIKE :terms OR name_kakasi LIKE :terms", terms: "%#{search_terms}%").
            order(Arel.sql sql_name).limit(50).
            map(&:name)
        end
        
        # check if file already exists on disk/collection
        collection_file_path = Doujin.dest_path_by_process_params(@info, full_path: true)
        if File.exist?(collection_file_path)
          doujin = Doujin.find_by_process_params(@info)
          
          c_size = helpers.number_to_human_size File.size(collection_file_path)
          c_imgs = doujin.try(:num_images) || 'N.D.'
          f_size = helpers.number_to_human_size File.size(@info[:file_path])
          f_imgs = @info[:images].size
          
          @collision_info = { collection: "#{c_imgs} pics/#{c_size}", current: "#{f_imgs} pics/#{f_size}", doujin: doujin }
        end
    end
  end # edit
  
  def rename_images
    @info = YAML.load_file(File.join @dname, 'info.yml')
    
    begin
      case params[:rename_with].to_sym
        when :alphabetical_index
          @info[:images].each_with_index{|img, i| img[:dst_path] = "%04d#{File.extname img[:src_path]}" % (i+1) }
        
        when :to_integer
          @info[:images].each{|img| img[:dst_path] = "%04d#{File.extname img[:src_path]}" % img[:src_path].to_i }
        
        when :regex_number
          re = Regexp.new params[:rename_regexp]
          @info[:images].each do |img|
            img[:dst_path] = "%04d#{File.extname img[:src_path]}" % img[:src_path].match(re)&.captures&.first.to_i
          end
        
        when :regex_pref_num, :regex_num_pref
          re = Regexp.new params[:rename_regexp]
          
          # create a sortable label
          invert_terms = params[:rename_with].to_sym == :regex_num_pref
          @info[:images].each do |img|
            prefix, num = img[:src_path].match(re)&.captures
            num, prefix = prefix, num if invert_terms
            img[:dst_sort_by] = "#{prefix}-#{'%050d' % num.to_i}"
          end
          
          # rename images sorted by the previous label
          @info[:images]
            .sort{|a,b| a[:dst_sort_by] <=> b[:dst_sort_by] }
            .each_with_index{|img, i| img[:dst_path] = "%04d#{File.extname img[:src_path]}" % (i+1) }
        
        when :regex_replacement
          re = Regexp.new params[:rename_regexp]
          @info[:images].each do |img|
            img[:dst_path] = img[:src_path].sub re, params[:rename_regexp_repl]
          end
        
        else
          raise 'unknown renaming method'
      end # case
      
      # append filenames
      @info[:images].each_with_index do |img, i|
        ext  = File.extname  img[:dst_path]
        name = File.basename img[:dst_path], ext
        img[:dst_path] = "#{name}-#{img[:src_path].sub(/\.[^\.]+$/, ext).tr File::SEPARATOR, '_'}"
      end if params[:keep_names] == 'true'
      
      @info[:images] = @info[:images].sort{|a,b| a[:dst_path] <=> b[:dst_path] }
      
      @info[:ren_images_method      ] = params[:rename_with]
      @info[:images_last_regexp     ] = params[:rename_regexp]
      @info[:images_last_regexp_repl] = params[:rename_regexp_repl]
      @info[:images_collision       ] = @info[:images].size != @info[:images].map{|i| i[:dst_path] }.uniq.size
      
      ProcessArchiveDecompressJob.crop_landscape_cover @dname, @info, @info[:landscape_cover_method]
      
      File.open(File.join(@dname, 'info.yml'), 'w'){|f| f.puts @info.to_yaml }
      
      redirect_to edit_process_path(id: params[:id], tab: params[:tab])
    rescue
      redirect_to(edit_process_path(id: params[:id], tab: params[:tab]), alert: $!.to_s)
    end
  end # rename_images
  
  def rename_file
    @info = YAML.load_file(File.join @dname, 'info.yml')
    
    if el = @info[:files].detect{|i| i[:src_path] == params[:path] }
      el[:dst_path] = params[:name]
      @info[:files] = @info[:files].sort{|a,b| a[:dst_path] <=> b[:dst_path] }
      @info[:files_collision] = @info[:files].size != @info[:files].map{|i| i[:dst_path] }.uniq.size
    elsif el = @info[:images].detect{|i| i[:src_path] == params[:path] }
      el[:dst_path] = params[:name]
      @info[:images] = @info[:images].sort{|a,b| a[:dst_path] <=> b[:dst_path] }
      @info[:images_collision] = @info[:images].size != @info[:images].map{|i| i[:dst_path] }.uniq.size
    end
    
    if el
      ProcessArchiveDecompressJob.crop_landscape_cover @dname, @info, @info[:landscape_cover_method]
      
      File.open(File.join(@dname, 'info.yml'), 'w'){|f| f.puts @info.to_yaml }
      render(json: {result: 'ok'})
    else
      render(json: {result: 'err', msg: "image not found [#{params[:name]}]" })
    end
  end # rename_file
  
  def show_image
    sub_path = File.expand_path(params[:path], '/')[1..-1] # sanitize input
    send_file File.join(@dname, 'contents', sub_path), disposition: :inline
  end # show_image
  
  # rezip archive, add metadata, move/register in collection, cleaup WIP folder
  def finalize_volume
    @info = YAML.load_file(File.join @dname, 'info.yml')
    
    unless @info[:dest_filename].to_s.end_with?('.zip')
      return redirect_to(edit_process_path(id: params[:id], tab: 'move'), alert: "destination filename not ending with \".zip\"")
    end
    
    if @info[:dest_folder].blank? && @info[:file_type] != 'artbook'
      return redirect_to(edit_process_path(id: params[:id], tab: 'ident'), alert: "empty destination folder")
    end
    
    unless @info[:dest_filename].present?
      return redirect_to(edit_process_path(id: params[:id], tab: 'move'), alert: "empty destination filename")
    end
    
    if @info[:overwrite] != true && @info[:db_doujin_id].nil? &&
       File.exist?(Doujin.dest_path_by_process_params(@info, full_path: true))
      return redirect_to(edit_process_path(id: params[:id], tab: 'move'), alert: "file already exists in collection")
    end
    
    perc_file = File.join(@dname, 'finalize.perc')
    @perc = File.read(perc_file).to_f rescue 0.0
    
    if request.post? # perform actions only via POST
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
  end # finalize_volume
  
  def show_externally
    respond_to do |format|
      format.json {
        ExternalProgramRunner.run params[:run], @fname
        render json: {ris: :done}
      }#json
    end
  end # show_externally
  
  
  private # ____________________________________________________________________
  
  
  def check_archive_file
    @fname = File.expand_path File.join(Setting['dir.to_sort'], params[:path])
    
    return redirect_to(process_index_path, alert: "file not found!") unless File.exist?(@fname)
    
    unless @fname.start_with?(Setting['dir.to_sort'])
      return redirect_to(process_index_path, alert: "file outside of working directory!")
    end
  end # check_archive_file
  
  def check_archive_folder
    @dname = File.expand_path File.join(Setting['dir.sorting'], params[:id])
    
    return redirect_to(process_index_path, alert: "folder not found!") unless File.exist?(@dname)
    
    unless @dname.start_with?(Setting['dir.sorting'])
      return redirect_to(process_index_path, alert: "folder outside of working directory!")
    end
  end # check_archive_folder
end
