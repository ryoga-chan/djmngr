class DoujinshiController < ApplicationController
  # https://api.rubyonrails.org/classes/ActionController/Live.html#method-i-send_stream
  include ActionController::Live
  
  THUMBS_PER_ROW = 6
  BATCH_SIZE     = 15 * THUMBS_PER_ROW
  ICONS = { 'artbook' => 'color_lens', 'magazine' => 'newspaper' }
  
  before_action :set_doujin_list_detail,
    only: %i[ index  favorites  search  scored  search_cover ]
  
  before_action :set_doujin,
    only: %i[ show  edit  score  read  read_pages  image  update  rehash  delete
              destroy  reprocess  shelf  compare_add ]

  # browse doujinshi by author/circle/folder
  def index
    @page_title = :collection
    
    return redirect_to(process_index_path, flash: {warn: 'collection is empty'}) unless Doujin.any?
    
    params[:tab] = 'author' unless %w{ author circle artbook magazine }.include?(params[:tab])
    
    # default doujin order (same as Doujin#label_name_latin)
    dj_sql_name = Arel.sql "LOWER( COALESCE(NULLIF(doujinshi.name_romaji, ''), NULLIF(doujinshi.name_kakasi, '')) )"
    
    case params[:tab]
      when 'author'
        sql_name = "COALESCE(NULLIF(authors.name_romaji, ''), NULLIF(authors.name_kakasi, ''))"
        # possibly lighter query:
        #   Author.select(Arel.sql "id, #{sql_name} AS name").where("id IN (SELECT author_id FROM authors_doujinshi)").
        @parents = Author.
          distinct.select(Arel.sql "authors.id, #{sql_name} AS name, authors.favorite").
          joins(:doujinshi).
          order(Arel.sql "authors.favorite DESC, LOWER(#{sql_name})")
        @doujinshi = Doujin.
          distinct.select("doujinshi.*").
          joins(:authors).
          where(authors: {id: params[:author_id]}).
          order(dj_sql_name) if params[:author_id]
      
      when 'circle'
        sql_name = "COALESCE(NULLIF(circles.name_romaji, ''), NULLIF(circles.name_kakasi, ''))"
        @parents = Circle.
          distinct.select(Arel.sql "circles.id, #{sql_name} AS name, circles.favorite").
          joins(:doujinshi).
          order(Arel.sql "circles.favorite DESC, LOWER(#{sql_name})")
        @doujinshi = Doujin.
          distinct.select("doujinshi.*").
          joins(:circles).
          where(circles: {id: params[:circle_id]}).
          order(dj_sql_name) if params[:circle_id]
      
      when 'artbook', 'magazine'
        rel = Doujin.where(category: params[:tab])
        @parents   = rel.order(:file_folder).distinct.pluck(:file_folder)
        @doujinshi = rel.where(file_folder: params[:folder]).order(dj_sql_name) if params[:folder]
    end
    
    if request.format.ereader?
      @parent_name = Author.find_by(id: params[:author_id].to_i).try(:label_name_latin) if params[:author_id]
      @parent_name = Circle.find_by(id: params[:circle_id].to_i).try(:label_name_latin) if params[:circle_id]
      @parent_name = params[:folder] if params[:folder]
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
        select(:id, :category, :file_folder, :file_name, :name_orig, :size, :num_images).
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
  
  def show
    @page_title = 'doujin details'
    
    msg = @doujin.check_hash?       ? [:notice,'same checksum'       ] : [:alert,'different checksum'] if params[:check_hash]
    msg = @doujin.check_zip?        ? [:notice,'zip test successfull'] : [:alert,'zip test failed'   ] if params[:check_zip]
    flash.now.send '[]=', *msg if msg
    
    respond_to do |format|
      format.any(:html, :ereader){ fresh_when @doujin }
      format.any(:webp, :jpg) {
        if stale?(last_modified: @doujin.created_at.utc, strong_etag: @doujin, template: false)
          # extract a frame (cli: `webpmux -get frame 1 out.webp -o -`)
          params[:page] = 0 unless (0..3).include?(params[:page].to_i)
          fname = @doujin.thumb_disk_path
          img = Vips::Image.webpload(fname, page: params[:page].to_i) # ImageProcessing::Vips.source(fname).call save: false
          data = request.format.webp? ?
            img.webpsave_buffer(Q: 70, lossless: false, min_size: true) :
            img.jpegsave_buffer(Q: 70, background: [255,255,255])
          send_data data,
            type: request.format.to_sym, disposition: :inline,
            filename: "#{@doujin.id}.#{request.format.to_sym}"
        end
      }# webp, jpg
      format.any(:zip, :cbz) {
        send_data @doujin.file_contents,
          type: request.format.to_sym, disposition: :attachment,
          filename: "#{@doujin.file_dl_name}.#{request.format.to_sym}"
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
      EpubConverterJob.perform_later params[:convert]
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
  
  # online reading
  def read
    if stale?(last_modified: @doujin.created_at.utc, strong_etag: @doujin)
      @page_title = :reader
      
      Zip::File.open(@doujin.file_path full: true) do |zip|
        @files = zip.entries.select{|e| e.file? && e.name =~ RE_IMAGE_EXT }.map(&:name).sort
      end
      
      params[:page] = params[:page].to_i
      params[:page] = 0 unless (0...@files.size).include?(params[:page])
    end
  end # read
  
  def read_pages
    p = params[:page].to_i == 0 ? 0 : (params[:page].to_i + 1) # don't count the first page
    ris = @doujin.update read_pages: p if p >= 0
    render json: (ris == false ? :err : :ok)
  end # read_pages
  
  # return the selected image extracting it from the ZIP file
  def image
    if stale?(last_modified: @doujin.created_at.utc, template: false,
              strong_etag: "doujin_#{@doujin.id}_image-F#{params[:file]}-P#{params[:page]}")
      Zip::File.open(@doujin.file_path full: true) do |zip|
        entry = zip.find_entry(params[:file]) if params[:file]
        entry = zip.entries.
          select{|e| e.file? && e.name =~ RE_IMAGE_EXT }.
          sort{|a,b| a.name <=> b.name }[params[:page].to_i] if params[:page]
        @fname   = entry&.name
        @content = entry&.get_input_stream&.read
      end
      
      unless @content
        @fname = 'not-found.png'
        @content = File.read(Rails.root.join 'public', @fname)
      end
      
      send_data @content, type: File.extname(@fname).delete('.').downcase.to_sym,
        disposition: :inline, filename: @fname
    end
  end # image

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
    redirect_to_with_format doujinshi_path
  end # destroy
  
  def reprocess
    # create original folder in /to_sort/reprocess
    dst_dir = File.expand_path File.join(Setting['dir.to_sort'], 'reprocess', File.dirname(@doujin.name_orig))
    FileUtils.mkdir_p dst_dir
    
    # move current ZIP file to that folder
    FileUtils.mv @doujin.file_path(full: true),
                 File.join(dst_dir, File.basename(@doujin.name_orig)), force: true
    
    # write current metadata
    md_path = File.join(dst_dir, "#{File.basename @doujin.name_orig, '.zip'}.yml")
    paths = @doujin.file_path.split(File::SEPARATOR, 3)
    dd_id = (paths[0] == 'author' ? @doujin.author_ids.first : (paths[0] == 'circle' ? @doujin.circle_ids.first : -1))
    File.atomic_write(md_path){|f| f.puts({
      author_ids:     @doujin.author_ids,
      circle_ids:     @doujin.circle_ids,
      doujin_dest_type: paths[0],
      doujin_dest_id: dd_id.to_s,
      file_type:      (%w{ author circle }.include?(paths[0]) ? 'doujin' : paths[0]),
      dest_folder:    paths[1],
      subfolder:      (paths[2].include?(File::SEPARATOR) ? File.dirname(paths[2]) : ''),
      dest_filename:  File.basename(paths[2]),
      score:          @doujin.score,
    }.to_yaml) }
    
    @doujin.destroy_with_files
    
    redirect_to prepare_archive_process_index_path(path: File.join('reprocess', @doujin.name_orig)),
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
    id = rel.order(:id).offset(n).limit(1).pluck :id
    redirect_to_with_format(doujin_path id: id)
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
