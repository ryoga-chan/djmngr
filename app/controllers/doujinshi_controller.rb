class DoujinshiController < ApplicationController
  # https://api.rubyonrails.org/classes/ActionController/Live.html#method-i-send_stream
  include ActionController::Live
  
  THUMBS_PER_ROW = 6
  BATCH_SIZE     = 15 * THUMBS_PER_ROW
  ICONS = {
    'author'    => 'supervisor_account',
    'circle'    => 'supervised_user_circle',
    'artbook'   => 'color_lens',
    'magazine'  => 'newspaper'
  }
  
  before_action :set_doujin_list_detail,
    only: %i[ index  favorites  search  scored  search_cover ]
  
  before_action :set_doujin,
    only: %i[ show  edit  score  read  read_pages  image  update  rehash  delete
              destroy  reprocess  shelf  compare_add ]

  # browse doujinshi by author/circle/folder
  def index
    @page_title = :collection
    
    return redirect_to(root_path, flash: {warn: 'collection is empty'}) unless Doujin.any?
    
    params[:tab] = 'author' unless %w{ author circle artbook magazine }.include?(params[:tab])
    
    # default doujin order (same as Doujin#label_name_latin)
    dj_sql_name = Arel.sql "LOWER( COALESCE(NULLIF(doujinshi.name_romaji, ''), NULLIF(doujinshi.name_kakasi, '')) )"
    
    def apply_filters(rel = nil)
      return nil unless rel
      
      rel = rel.where('doujinshi.language' =>          params[:lan]          ) if params[:lan].present?
      rel = rel.where('doujinshi.censored' =>          params[:cen] == 'true') if params[:cen].present?
      rel = rel.where('doujinshi.colorized' =>         params[:col] == 'true') if params[:col].present?
      rel = rel.where('doujinshi.reading_direction' => params[:dir]          ) if params[:dir].present?
      rel = rel.where('doujinshi.media_type' =>        params[:med]          ) if params[:med].present?
      rel = rel.where('doujinshi.favorite' =>          params[:fav] == 'true') if params[:fav].present?
      case params[:sco]
        when 'nd'         then rel = rel.where('doujinshi.score' => nil)
        when /\A[0-9]+\z/ then rel = rel.where('doujinshi.score' => params[:sco].to_i)
      end
      
      rel
    end # apply_filters
    
    case params[:tab]
      when 'author'
        sql_name = "COALESCE(NULLIF(authors.name_romaji, ''), NULLIF(authors.name_kakasi, ''))"
        # possibly lighter query:
        #   Author.select(Arel.sql "id, #{sql_name} AS name").where("id IN (SELECT author_id FROM authors_doujinshi)").
        @parents = apply_filters Author.
          distinct.select(Arel.sql "authors.id, #{sql_name} AS name, authors.favorite").
          joins(:doujinshi).
          order(Arel.sql "authors.favorite DESC, LOWER(#{sql_name})")
        @doujinshi = apply_filters Doujin.
          distinct.select("doujinshi.*").
          joins(:authors).
          where(authors: {id: params[:author_id]}).
          order(dj_sql_name) if params[:author_id].present?
      
      when 'circle'
        sql_name = "COALESCE(NULLIF(circles.name_romaji, ''), NULLIF(circles.name_kakasi, ''))"
        @parents = apply_filters Circle.
          distinct.select(Arel.sql "circles.id, #{sql_name} AS name, circles.favorite").
          joins(:doujinshi).
          order(Arel.sql "circles.favorite DESC, LOWER(#{sql_name})")
        @doujinshi = apply_filters Doujin.
          distinct.select("doujinshi.*").
          joins(:circles).
          where(circles: {id: params[:circle_id]}).
          order(dj_sql_name) if params[:circle_id].present?
      
      when 'artbook', 'magazine'
        rel = apply_filters Doujin.where(category: params[:tab])
        @parents   = rel.order(:file_folder).distinct.pluck(:file_folder)
        @doujinshi = rel.where(file_folder: params[:folder]).order(dj_sql_name) if params[:folder].present?
    end
    
    if request.format.ereader?
      @parent_name = Author.find_by(id: params[:author_id].to_i).try(:label_name_latin) if params[:author_id].present?
      @parent_name = Circle.find_by(id: params[:circle_id].to_i).try(:label_name_latin) if params[:circle_id].present?
      @parent_name = params[:folder] if params[:folder].present?
      # group by first letter
      @parents = @parents.inject({}) do |h, i|
        key = (i.try(:name) || i)[0].upcase # Author/Circle/String
        h[key] = (h[key] || []).push i
        h
      end
      @letters = @parents.keys.sort
      params[:letter] = @letters.first unless @letters.include?(params[:letter])
    end # ereader format
  end # index
  
  def search
    @page_title = 'doujin search'
    
    if %w{ authors circles themes }.include?(params[:where])
      return redirect_to(controller: params[:where], action: :index, term: params[:term])
    end
    
    @doujinshi = Doujin.search(params[:term]).limit(THUMBS_PER_ROW * 5)
    
    if request.format.json? || request.format.tsv?
      max_results = THUMBS_PER_ROW * 2
      
      @doujinshi = @doujinshi.
        reselect(:id, :category, :file_folder, :file_name, :name_orig, :size, :num_images, :score).
        limit(max_results)
      
      @deleted_doujinshi = DeletedDoujin.
        search(params[:term]).
        select(:id, :name, :name_kakasi, :size, :num_images).
        limit(max_results)
      
      @processable_doujinshi = ProcessableDoujin.
        search(params[:term]).
        select(:id, :name, :name_kakasi, :size).
        limit(max_results)
      
      file_dl_opts = { type: request.format.to_sym, disposition: :attachment,
                       filename: "search-results.#{request.format.to_sym}" }
    end
    
    respond_to do |format|
      format.html
      format.ereader
      format.json {
        if params[:js_finder]
          render json: @doujinshi.limit(25).map{|d|
            info = {
              id:     d.id,
              descr:  d.file_dl_name(omit_ext: true),
              descr2: d.name_orig.sub('.zip', ''),
              link:   doujin_path(d),
              thumb:  d.thumb_path,
              tag:    "#{d.score || '--'} &star;",
              tag2:   "#{d.num_images} P &nbsp;&middot;&nbsp; #{helpers.number_to_human_size(d.size)}",
            }
            info[:descr2] = nil if info[:descr] == info[:descr2]
            info
          }
        else
          send_stream(**file_dl_opts) do |stream|
            stream.write %Q|{\n"saved":[|
            @doujinshi.each_with_index{|d, i|
              info = { id: d.id, name: d.file_dl_name, name_orig: d.name_orig, size: d.size, pages: d.num_images }
              stream.write info.to_json.prepend(i != 0 ? ',' : '') }
            stream.write %Q|],\n"deleted":[|
            @deleted_doujinshi.each_with_index{|d, i|
              info = { id: d.id, name: d.name_kakasi, name_orig: d.name, size: d.size, pages: d.num_images }
              stream.write info.to_json.prepend(i != 0 ? ',' : '') }
            stream.write %Q|],\n"todo":[|
            @processable_doujinshi.each_with_index{|d, i|
              info = { id: d.id, name: d.name_kakasi, name_orig: d.name, size: d.size, pages: 0 }
              stream.write info.to_json.prepend(i != 0 ? ',' : '') }
            stream.write %Q|]\n}|
          end # send_stream
        end
      }#json
      format.tsv {
        send_stream(**file_dl_opts) do |stream|
          stream.write %w{ TYPE ID NAME NAME_ORIG SIZE PAGES }.join("\t")+"\n"
          @doujinshi.each_with_index{|d, i|
            stream.write [:saved, d.id, d.file_dl_name, d.name_orig, d.size, d.num_images].join("\t")+"\n" }
          @deleted_doujinshi.each_with_index{|d, i|
            stream.write [:deleted, d.id, d.name_kakasi, d.name, d.size, d.num_images].join("\t")+"\n" }
          @processable_doujinshi.each_with_index{|d, i|
            stream.write [:todo, d.id, d.name_kakasi, d.name, d.size, 0].join("\t")+"\n" }
        end
      }#tsv
    end
  end # search
  
  def js_finder
    request.format = :json
    params[:js_finder] = true
    return search
  end # js_finder
  
  def show
    @page_title = 'doujin details'
    
    msg = @doujin.check_hash?       ? [:notice,'same checksum'       ] : [:alert,'different checksum'] if params[:check_hash]
    msg = @doujin.check_zip?        ? [:notice,'zip test successfull'] : [:alert,'zip test failed'   ] if params[:check_zip]
    flash.now.send '[]=', *msg if msg
    
    respond_to do |format|
      format.any(:html, :ereader)
      format.any(:webp, :jpg) {
        if stale?(last_modified: @doujin.created_at.utc, strong_etag: @doujin, template: false)
          # extract a frame (cli: `webpmux -get frame 1 out.webp -o -`)
          params[:page] = 0 unless (0..3).include?(params[:page].to_i)
          fname = @doujin.thumb_disk_path
          img = Vips::Image.webpload(fname, page: params[:page].to_i) # ImageProcessing::Vips.source(fname).call save: false
          data = request.format.webp? ?
            img.webpsave_buffer(Q: IMG_QUALITY_THUMB, lossless: false, min_size: true) :
            img.jpegsave_buffer(Q: IMG_QUALITY_THUMB, background: [255,255,255])
          send_data data,
            type: request.format.to_sym, disposition: :inline,
            filename: "#{@doujin.id}.#{request.format.to_sym}"
        end
      }# webp, jpg
      format.any(:zip, :cbz) {
        send_file @doujin.file_path(full: true), buffer_size: 512.kilobyte,
          type: request.format.to_sym, disposition: :attachment,
          filename: "#{@doujin.file_dl_name omit_ext: true}.#{request.format.to_sym}"
      }# zip, cbz
      format.json {
        target = @doujin.file_path(full: true)
        target = File.dirname target if params[:run] == 'terminal'
        ExternalProgramRunner.run params[:run], target
        render json: {ris: :done}
      }#json
    end
  end # show
  
  def score
    score = params[:score].to_i
    score = nil unless (1..10).include?(score)
    flash[:alert] = "unable to update the score" unless @doujin.update(score: score)
    redirect_to_with_format doujin_path(@doujin, params.permit(%w{ from_author from_circle }).to_h)
  end # score
  
  # run new conversions and manage converted files
  def epub
    @page_title = :epub
    
    @pub_dir = Rails.root.join('public').to_s
    
    if params[:convert]
      EpubConverterJob.perform_later params[:convert], params.permit(:name, :width, :height).to_h
      sleep 3
      flash[:notice] = "now converting doujin ID [#{params[:convert]}]"
      return redirect_to_with_format(epub_doujinshi_path)
    end
    
    fname = File.expand_path File.join(@pub_dir, 'epub', params[:remove].to_s)
    if params[:remove].present? && fname.start_with?(@pub_dir) && File.exist?(fname)
      File.unlink     fname if fname.end_with?('.perc') || fname.end_with?('.epub')
      FileUtils.rm_rf fname.sub(/perc$/, 'wip') if fname.end_with?('.perc')
      return redirect_to_with_format(epub_doujinshi_path)
    end
    
    @wip, @done = Dir[ File.join(@pub_dir, 'epub', '*.{epub,perc}') ].
      sort.partition{|i| i.end_with? '.perc' }
  end # epub
  
  def zip_select4read
    f = ExternalProgramRunner.run('file_picker', nil)
    
    File.exist?(f.to_s) ?
      redirect_to(zip_read_doujinshi_path file: f, format: :ereader) :
      redirect_to(root_path, alert: "file not found: [#{f}]")
  end # zip_select4read
  
  # read images within a ZIP file
  def zip_read
    @page_title = :reader
    
    case params[:model]
      when 'Doujin'.freeze
        if d = Doujin.find_by(id: params[:id])
          params[:file    ]   = d.file_path(full: true)
          @jump_to = { url: read_doujin_path, params: params.permit(:id, :model, :ret_url, :from_format) }
          params[:ret_url ] ||= doujin_path(id: params[:id], format: params[:from_format])
          params[:turn_url]   = read_pages_doujin_path(id: params[:id], format: '')
        end
      when 'ProcessableDoujin'.freeze
        if d = ProcessableDoujin.find_by(id: params[:id])
          params[:file    ]   = d.file_path(full: true)
          @jump_to = { url: read_process_path, params: params.permit(:id, :model, :ret_url, :from_format) }
          params[:ret_url ] ||= process_index_path(format: params[:from_format])
          params.delete :turn_url
        end
      else # read from a generic ZIP file
        if params[:file].blank? || !File.exist?(params[:file])
          flash.now[:alert] = %Q|file "#{params[:file]}" not found|
          return render(inline: '', layout: true)
        end
        @jump_to = { url: zip_read_doujinshi_path, params: params.permit(:file, :turn_url, :ret_url, :from_format) }
        params[:ret_url] ||= root_path(format: params[:from_format])
    end # case
    
    # create a unique fingerprint for external files that may change and overlap to old ones
    if params[:model] != 'Doujin'.freeze
      fs = File.stat params[:file]
      params[:fhash] = Digest::MD5.hexdigest "#{params[:file]}:#{fs.size}@#{fs.mtime.to_i}"
    end
    
    Zip::File.open(params[:file]){|zip| @num_files = zip.image_entries.size }
    
    params[:page] = params[:page].to_i
    params[:page] = 0 unless (0...@num_files).include?(params[:page])
  end # zip_read
  
  # return the selected image by extracting it from the ZIP file
  def zip_image
    file_updated_at = Time.now
  
    # file_path, page_num, turn_url, return_url
    case params[:model]
      when 'Doujin'.freeze
        if d = Doujin.find_by(id: params[:id])
          file_updated_at = d.created_at
          params[:file] = d.file_path(full: true)
        end
      when 'ProcessableDoujin'.freeze
        if d = ProcessableDoujin.find_by(id: params[:id])
          file_updated_at = d.created_at
          params[:file] = d.file_path(full: true)
        end
      else
        if params[:file].blank? || !File.exist?(params[:file])
          return render(plain: 'file not found', status: :not_found)
        end
        file_updated_at = File.mtime(params[:file])
    end # case

    if stale?(last_modified: file_updated_at.utc, template: false,
              strong_etag: "#{params[:model] || params[:file]}-#{params[:id] || 0}_page-#{params[:page]}_#{params[:w]}x#{params[:h]}")
      Zip::File.open(params[:file]) do |zip|
        entry = zip.image_entries(sort: true)[params[:page].to_i]
        @fname   = File.basename entry&.name.to_s
        @content = entry&.get_input_stream&.read
      end
      
      if @content # downsize image to the specified resolution
        maxw, maxh = params[:w].to_i, params[:h].to_i
        
        if maxw > 0 && maxh > 0
          @fname = "#{File.basename @fname, '.*'}.jpg"
          @content = Vips::Image.
            new_from_buffer(@content, '').
            resize_to_fit(maxw, maxh).
            jpegsave_buffer(Q: IMG_QUALITY_RESIZE)
        end
      else
        @fname = 'not-found.png'
        @content = File.binread(Rails.root.join 'public', @fname)
      end
      
      send_data @content, type: File.extname(@fname).delete('.').downcase.to_sym,
        disposition: :inline, filename: @fname
    end
  end # zip_image
  
  def read_pages
    p = params[:page].to_i == 0 ? 0 : (params[:page].to_i + 1) # don't count the first page
    ris = @doujin.update read_pages: p if p >= 0
    render json: (ris == false ? :err : :ok)
  end # read_pages
  
  def update
    @page_title = 'edit doujin'
    
    doujin_params = params.require(:doujin).
      permit(:name, :name_romaji, :name_kakasi, :name_orig, :name_eng, :reading_direction,
             :read_pages, :language, :censored, :colorized, :media_type, :notes, :file_name,
             {author_ids: []}, {circle_ids: []})
    
    @doujin.update(doujin_params) ?
      redirect_to(doujin_path(@doujin, params.permit(:from_author, :from_circle)), notice: "doujin [#{params[:id]}] updated") :
      render(:edit, status: :unprocessable_entity)
  end # update
  
  def rehash
    msg = @doujin.refresh_checksum! ? {notice: 'checksum refreshed'} : {alert: 'checksum error'}
    redirect_to doujin_path(@doujin, params.permit(:from_author, :from_circle)), flash: msg
  end # rehash
  
  def delete = nil
  
  def destroy
    @doujin.destroy_with_files
    flash[:notice] = "doujin [#{@doujin.id}] deleted"
    return redirect_to_with_format(doujinshi_path tab: :author, author_id: params[:from_author], anchor: :listing) if params[:from_author]
    return redirect_to_with_format(doujinshi_path tab: :circle, circle_id: params[:from_circle], anchor: :listing) if params[:from_circle]
    redirect_to_with_format doujinshi_path
  end # destroy
  
  def reprocess
    # create original folder in /to_sort/#{DJ_DIR_REPROCESS}
    dst_dir = File.expand_path File.join(Setting['dir.to_sort'], DJ_DIR_REPROCESS, File.dirname(@doujin.name_orig))
    FileUtils.mkdir_p dst_dir
    
    # write current metadata
    md_path = File.join(dst_dir, "#{File.basename @doujin.name_orig, '.zip'}.yml")
    paths = @doujin.file_path.split(File::SEPARATOR, 3)
    dd_id = (paths[0] == 'author' ? @doujin.author_ids.first : (paths[0] == 'circle' ? @doujin.circle_ids.first : -1))
    is_author_or_circle = %w{ author circle }.include? paths[0]
    File.atomic_write(md_path){|f| f.puts({
      author_ids:     @doujin.author_ids,
      circle_ids:     @doujin.circle_ids,
      doujin_dest_type: paths[0],
      doujin_dest_id: dd_id.to_s,
      file_type:      (is_author_or_circle ? 'doujin' : paths[0]),
      dest_folder:    (is_author_or_circle ? paths[1] : (paths[2] ? paths[1] : '')),
      subfolder:      (paths[2].to_s.include?(File::SEPARATOR) ? File.dirname(paths[2]) : ''),
      dest_filename:  File.basename(paths[2] || paths[1]),
      score:          @doujin.score,
      language:       @doujin.language,
      censored:       @doujin.censored,
      colorized:      @doujin.colorized,
      media_type:     @doujin.media_type,
    }.to_yaml) }
    
    # move current ZIP file to that folder
    dst_path = File.join dst_dir, File.basename(@doujin.name_orig)
    FileUtils.mv @doujin.file_path(full: true), dst_path, force: true
    ProcessIndexRefreshJob.add_entry dst_path
    
    @doujin.destroy_with_files track: false
    
    redirect_to prepare_archive_process_index_path(path: File.join(DJ_DIR_REPROCESS, @doujin.name_orig)),
      notice: "doujin removed from collection, processing auto started"
  end # reprocess
  
  def fav_toggle
    return render(json: {result: :err, msg: 'type error'}) unless %w{ Author Circle Doujin }.include?(params[:type])
    
    record = params[:type].constantize.find_by id: params[:id]
    return render(json: {result: :err, msg: "#{params[:type]} [#{params[:id]}] not found"}) unless record
    
    record.update(favorite: !record.favorite?) ?
      render(json: {result: :ok, favorite: record.favorite?}) :
      render(json: {result: :err, msg: record.errors.full_messages.map{|m| "- #{m}"}.join("\n") })
  end # fav_toggle
  
  def favorites
    @page_title = :faves
    
    params[:sort] = 'date' unless %w{ name date }.include?(params[:sort])
    
    sql_name = "COALESCE(NULLIF(name_romaji, ''), NULLIF(name_kakasi, ''))"
    
    sql_sort_by = params[:sort] == 'date' ? {faved_at: :desc} : Arel.sql(sql_name)
    sql_select  = Arel.sql "id, #{sql_name} AS name, favorite, faved_at"
    @authors    = Author.select(sql_select).where(favorite: true).order(sql_sort_by)
    @circles    = Circle.select(sql_select).where(favorite: true).order(sql_sort_by)

    sql_sort_by = params[:sort] == 'date' ? {faved_at: :desc} : :name_kakasi
    @doujinshi  = Doujin.where(favorite: true).order(sql_sort_by)
    
    if request.format.ereader?
      params[:tab] = 'doujin' unless %w{ doujin author circle }.include?(params[:tab])
    end
  end # favorites
  
  def scored
    @page_title = :scores
    
    @doujinshi = Doujin.page(params[:page])#.per(2)

    if [params[:score_min], params[:score_max]].include?('ND')
      @doujinshi = @doujinshi.where(score: nil).order(:name_kakasi)
    else
      # sanitize params
      params[:score_max], params[:score_min] = params[:score_max].to_i, params[:score_min].to_i
      params[:score_min] = 8  unless (1..10).include?(params[:score_min])
      params[:score_max] = 10 unless (1..10).include?(params[:score_max])
      params[:score_min] = params[:score_max] if params[:score_min] > params[:score_max]
      
      @doujinshi = @doujinshi.
        where("? <= score AND score <= ?", params[:score_min], params[:score_max]).
        reorder(score: :desc)
    end
  end # scored
  
  # curl -L -F cover=@path/to/img.ext http://localhost:3000/doujinshi/search_cover.json
  def search_cover
    @page_title = 'cover search'
    
    if request.post? && params[:cover]
      cover_hash = CoverMatchingJob.hash_image params[:cover].tempfile.path
    end
    
    # download and hash an image file
    url = URI.parse(params[:url]) rescue nil
    if url.is_a?(URI::HTTP)
      image_data = URI.open(params[:url], read_timeout: 10).read rescue File.read(File.join Rails.root, 'public', 'not-found.png')
      f = Tempfile.open{|f| f.write(image_data); f }
      cover_hash = CoverMatchingJob.hash_image f.path
      f.unlink
    end
    
    if cover_hash
      CoverMatchingJob.perform_later cover_hash
      return redirect_to(hash: cover_hash, format: params[:format])
    end
    
    fname = File.join(Setting['dir.sorting'], 'cover-search.yml').to_s
    
    # save/load search data
    @result = CoverMatchingJob.results params[:hash]
    if @result.is_a?(Hash)       # save completed search results
      File.open(fname, 'w'){|f| f.puts @result.to_yaml }
    elsif @result == :not_found  # job completed, load last search results
      @result = YAML.unsafe_load_file(fname) rescue :not_found
    end
    
    # find doujinshi
    if @result.is_a?(Hash)
      @doujinshi = @result[:results].map do |id, perc|
        next unless d = Doujin.find_by(id: id)
        d.cover_similarity = perc
        d
      end
      
      @doujinshi_deleted = @result[:results_deleted].map do |id, perc|
        next unless d = DeletedDoujin.find_by(id: id)
        d.cover_similarity = perc
        d
      end
    end

    file_dl_opts = { type: request.format.to_sym, disposition: :attachment,
                     filename: "search-results.#{request.format.to_sym}" }
    respond_to do |format|
      format.html
      format.json {
        send_stream(**file_dl_opts) do |stream|
          stream.write %Q|[|
          @doujinshi.each_with_index{|d, i|
            info = { id: d.id, name: d.file_dl_name, name_orig: d.name_orig, size: d.size,
                     pages: d.num_images, similarity: d.cover_similarity }
            stream.write info.to_json.prepend(i != 0 ? ',' : '') }
          stream.write %Q|]|
        end
      }#json
      format.tsv {
        send_stream(**file_dl_opts) do |stream|
          stream.write %w{ ID NAME NAME_ORIG SIZE PAGES SIMILARITY }.join("\t")+"\n"
          @doujinshi.each_with_index{|d, i|
            stream.write [d.id, d.file_dl_name, d.name_orig, d.size, d.num_images, d.cover_similarity].join("\t")+"\n" }
        end
      }#tsv
    end
  end # search_cover
  
  def random_pick
    return redirect_to_with_format(root_path) unless %w{ book faved scored }.include?(params[:type])
    
    rel = Doujin.where.not(media_type: :manga)
    
    rel = case params[:type]
      when 'book'  ; rel
      when 'faved' ; rel.where favorite: true
      when 'scored'; rel.where("8 <= score AND score <= 10")
    end

    n  = SecureRandom.random_number rel.count
    id = rel.order(:id).offset(n).limit(1).pluck(:id).first
    
    id ? redirect_to_with_format(doujin_path id: id) :
      redirect_to(root_path, flash: {warn: 'collection is empty'})
  end # random_pick
  
  # add/remove doujin from a shelf (creates a new shelf if requested)
  def shelf
    # remove from shelf
    Shelf.find_by(id: params[:rm_shelf_id].to_i).try :rm_doujin, @doujin.id
    
    if params[:shelf_id].to_i == 0 && params[:shelf_name].present? # create shelf and add
      Shelf.create(name: params[:shelf_name].strip).add_doujin @doujin.id
    else # add to existing shelf
      Shelf.find_by(id: params[:shelf_id].to_i).try :add_doujin, @doujin.id
    end
    
    redirect_to_with_format doujin_path(@doujin)
  end # shelf

  def compare_add
    DoujinCompareJob.perform_now doujin: @doujin
    redirect_to compare_doujinshi_path
  end # compare_add
  
  def compare
    @page_title = :compare
    @entries = DoujinCompareJob.data
  end # compare
  
  # change associations and folder of a list of doujinshi
  # like those of a specific doujin
  def move
    unless dest = Doujin.find_by(id: params[:doujin_id])
      return redirect_to(doujinshi_path, flash: {alert: "doujin [#{params[:doujin_id]}] not found!"})
    end
    
    counters = { num: 0, true => 0, false => 0, :dupe => 0}
    Doujin.where(id: params[:ids]).each do |d|
      counters[:num] += 1
      counters[d.move_to dest] += 1
    end
    
    index_params = case
      when dest.authors.any? then { tab: :author, author_id: dest.author_ids.first }
      when dest.circles.any? then { tab: :circle, circle_id: dest.circle_ids.first }
      else { tab: dest.category, folder: dest.file_folder }
    end
    
    msg  = "move #{counters[:num]} doujinshi: #{counters[true]} ok"
    msg += ", #{counters[:dupe]} DUPES"  if counters[:dupe] > 0
    msg += ", #{counters[false]} ERRORS" if counters[false] > 0
    redirect_to doujinshi_path(index_params), notice: msg
  end # move


  private # ____________________________________________________________________


  def set_doujin
    unless @doujin = Doujin.find_by(id: params[:id])
      flash[:alert] = "doujin [#{params[:id]}] not found!"
      return redirect_to_with_format(doujinshi_path)
    end
  end # set_doujin
  
  def redirect_to_with_format(url_or_options)
    return html_redirect_to(url_or_options) if request.format.ereader?
    redirect_to url_or_options
  end # redirect_to_with_format
end
