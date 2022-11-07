class DoujinshiController < ApplicationController
  THUMBS_PER_ROW = 6
  BATCH_SIZE     = 15 * THUMBS_PER_ROW
  
  before_action :set_index_detail, only: %i[ index favorites search ]
  before_action :set_doujin, only: %i[ show edit score read read_pages image update rehash destroy reprocess ]

  # browse doujinshi by author/circle/folder
  def index
    return redirect_to(process_index_path, flash: {warn: 'collection is empty'}) unless Doujin.any?
    
    params[:tab] = 'author' unless %w{ author circle artbook magazine }.include?(params[:tab])
    
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
          order(:name_kakasi) if params[:author_id]
      
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
          order(:name_kakasi) if params[:circle_id]
      
      when 'artbook', 'magazine'
        rel = Doujin.where(category: params[:tab])
        @parents   = rel.order(:file_folder).distinct.pluck(:file_folder)
        @doujinshi = rel.where(file_folder: params[:folder]).order(:name_kakasi) if params[:folder]
    end
    
    if request.format.to_sym == :ereader
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
    if %w{ authors circles themes }.include?(params[:where])
      return redirect_to(controller: params[:where], action: :index, term: params[:term])
    end
    
    @doujinshi = Doujin.search(params[:term]).limit(THUMBS_PER_ROW * 5)
    
    respond_to do |format|
      format.html
      format.ereader
      format.json { render json: @doujinshi }#json
      format.tsv {
        header = Doujin.column_names.join("\t")
        data = @doujinshi.inject(header){|s, d| s += d.attributes.values.join("\t").prepend("\n") }
        send_data data,
          type: request.format.to_sym, disposition: :attachment,
          filename: "search-results.#{request.format.to_sym}"
      }#tsv
    end
  end # search
  
  def show
    msg = @doujin.check_hash?       ? [:notice,'same checksum'       ] : [:alert,'different checksum'] if params[:check_hash]
    msg = @doujin.check_zip?        ? [:notice,'zip test successfull'] : [:alert,'zip test failed'   ] if params[:check_zip]
    flash.now.send '[]=', *msg if msg
    
    respond_to do |format|
      format.html
      format.ereader
      format.any(:webp, :jpg) {
        # extract a frame (cli: `webpmux -get frame 1 out.webp -o -`)
        params[:page] = 0 unless (0..3).include?(params[:page].to_i)
        fname = Rails.root.join('public', 'thumbs', "#{@doujin.id}.webp").to_s
        img = Vips::Image.webpload(fname, page: params[:page].to_i) # ImageProcessing::Vips.source(fname).call save: false
        data = request.format.to_sym == :webp ?
          img.webpsave_buffer(Q: 70, lossless: false, min_size: true) :
          img.jpegsave_buffer(Q: 70, background: [255,255,255])
        send_data data,
          type: request.format.to_sym, disposition: :inline,
          filename: "#{@doujin.id}.#{request.format.to_sym}"
      }# webp, jpg
      format.any(:zip, :cbz) {
        send_data @doujin.file_contents,
          type: request.format.to_sym, disposition: :attachment,
          filename: "#{@doujin.file_dl_name}.#{request.format.to_sym}"
      }# zip, cbz
      format.json {
        if params[:run] == 'mcomix'
          system %Q| mcomix -f #{@doujin.file_path(full: true).shellescape} & |
          return render json: {ris: :ok}
        end
        render json: ''
      }#json
    end
  end # show
  
  def score
    flash[:alert] = "unable to update the score" unless @doujin.update(params.permit(:score))
    redirect_to_with_format doujin_path(@doujin, params.permit(%w{ from_author from_circle }).to_h)
  end # score
  
  # run new conversions and manage converted files
  def epub
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
    Zip::File.open(@doujin.file_path full: true) do |zip|
      @files = zip.glob('*.{jpg,jpeg,png,gif}').map(&:name).sort
    end
    
    params[:page] = params[:page].to_i
    params[:page] = 0 unless (0...@files.size).include?(params[:page])
  end # read
  
  def read_pages
    ris = @doujin.update read_pages: (params[:page].to_i + 1) if params[:page].present? && params[:page].to_i >= 0
    render json: (ris == false ? :err : :ok)
  end # read_pages
  
  # return the selected image extracting it from the ZIP file
  def image
    Zip::File.open(@doujin.file_path full: true) do |zip|
      entry = zip.find_entry(params[:file]) if params[:file]
      entry = zip.glob('*.{jpg,jpeg,png,gif}').sort{|a,b| a.name <=> b.name }[params[:page].to_i] if params[:page]
      @fname   = entry&.name
      @content = entry&.get_input_stream&.read
    end
    
    unless @content
      @fname = 'img-not-found.png'
      @content = File.read(Rails.root.join 'public', @fname)
    end
    
    send_data @content, type: File.extname(@fname).delete('.').to_sym,
      disposition: :inline, filename: @fname
  end # image

  def update
    doujin_params = params.require(:doujin).
      permit(:name, :name_romaji, :name_kakasi, :name_orig, :reading_direction,
             :read_pages, :language, :censored, :colorized, :notes, :file_name)
    
    @doujin.update(doujin_params) ?
      redirect_to(doujin_path(@doujin, params.permit(:from_author, :from_circle)), notice: "doujin [#{params[:id]}] updated") :
      render(:edit, status: :unprocessable_entity)
  end # update
  
  def rehash
    msg = @doujin.refresh_checksum! ? {notice: 'checksum refreshed'} : {alert: 'checksum error'}
    redirect_to doujin_path(@doujin, params.permit(:from_author, :from_circle)), flash: msg
  end # rehash
  
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
    params[:sort] = 'date' unless %w{ name date }.include?(params[:sort])
    
    sql_name = "COALESCE(NULLIF(name_romaji, ''), NULLIF(name_kakasi, ''))"
    
    sql_sort_by = params[:sort] == 'date' ? {faved_at: :desc} : Arel.sql(sql_name)
    sql_select  = Arel.sql "id, #{sql_name} AS name, favorite, faved_at"
    @authors    = Author.select(sql_select).where(favorite: true).order(sql_sort_by)
    @circles    = Circle.select(sql_select).where(favorite: true).order(sql_sort_by)

    sql_sort_by = params[:sort] == 'date' ? {faved_at: :desc} : :name_kakasi
    @doujinshi  = Doujin.where(favorite: true).order(sql_sort_by)
    
    if request.format.to_sym == :ereader
      params[:tab] = 'doujin' unless %w{ doujin author circle }.include?(params[:tab])
    end
  end # favorites


  private # ____________________________________________________________________


  def set_doujin
    unless @doujin = Doujin.find_by(id: params[:id])
      flash[:alert] = "doujin [#{params[:id]}] not found!"
      return redirect_to_with_format(doujinshi_path)
    end
  end # set_doujin
  
  def set_index_detail
    session[:dj_index_detail] = params[:detail] if %w{ thumbs table }.include?(params[:detail])
    session[:dj_index_detail] ||= 'table'
  end # set_index_detail
  
  def redirect_to_with_format(url_or_options)
    return html_redirect_to(url_or_options) if request.format.to_sym == :ereader
    redirect_to url_or_options
  end # redirect_to_with_format
end
