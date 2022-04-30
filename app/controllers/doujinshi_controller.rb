class DoujinshiController < ApplicationController
  before_action :set_doujin,
    only: %i[ show edit update delete destroy score read read_pages image ]

  # browse doujinshi by author/circle/folder
  def index
    params[:tab] = 'author' unless %w{ author circle artbook magazine }.include?(params[:tab])
    
    session[:dj_index_detail] = params[:detail] if %w{ thumbs table }.include?(params[:detail])
    session[:dj_index_detail] ||= 'table'
    
    case params[:tab]
      when 'author'
        sql_name = "COALESCE(NULLIF(authors.name_romaji, ''), NULLIF(authors.name_kakasi, ''))"
        # possibly lighter query:
        #   Author.select(Arel.sql "id, #{sql_name} AS name").where("id IN (SELECT author_id FROM authors_doujinshi)").
        @parents = Author.
          distinct.select(Arel.sql "authors.id, #{sql_name} AS name").
          joins(:doujinshi).
          order(Arel.sql "LOWER(#{sql_name})")
        @doujinshi = Doujin.
          distinct.select("doujinshi.*").
          joins(:authors).
          where(authors: {id: params[:author_id]}).
          order(:name_kakasi) if params[:author_id]
      
      when 'circle'
        sql_name = "COALESCE(NULLIF(circles.name_romaji, ''), NULLIF(circles.name_kakasi, ''))"
        @parents = Circle.
          distinct.select(Arel.sql "circles.id, #{sql_name} AS name").
          joins(:doujinshi).
          order(Arel.sql "LOWER(#{sql_name})")
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
  
  def show
    msg = @doujin.check_hash?       ? [:notice,'same checksum'       ] : [:alert,'different checksum'] if params[:check_hash]
    msg = @doujin.check_zip?        ? [:notice,'zip test successfull'] : [:alert,'zip test failed'   ] if params[:check_zip]
    msg = @doujin.refresh_checksum! ? [:notice,'checksum refreshed'  ] : [:alert,'checksum error'    ] if params[:rehash]
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
    ris = @doujin.update read_pages: params[:page].to_i if params[:page].present? && params[:page].to_i >= 0
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
             :read_pages, :language, :censored, :colorized, :notes)
    
    @doujin.update(doujin_params) ?
      redirect_to(doujin_path(@doujin, params.permit(:from_author, :from_circle)), notice: "doujin [#{params[:id]}] updated") :
      render(:edit, status: :unprocessable_entity)
  end # update
  
  def destroy
    @doujin.destroy_with_files
    flash[:notice] = "doujin [#{@doujin.id}] deleted"
    redirect_to_with_format doujinshi_path
  end # destroy


  private # ____________________________________________________________________


  def set_doujin
    unless @doujin = Doujin.find_by(id: params[:id])
      flash[:alert] = "doujin [#{params[:id]}] not found!"
      return redirect_to_with_format(doujinshi_path)
    end
  end # set_doujin
  
  def redirect_to_with_format(url_or_options)
    return html_redirect_to(url_or_options) if request.format.to_sym == :ereader
    redirect_to url_or_options
  end # redirect_to_with_format
end
