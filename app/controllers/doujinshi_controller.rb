class DoujinshiController < ApplicationController
  layout -> { return 'ereader' if request.format.to_sym == :ereader }
  
  before_action :set_doujin, only: %i[ show edit update destroy score read ]

  # browse doujinshi by author/circle/folder
  def index
    params[:tab] = 'author' unless %w{ author circle artbook magazine }.include?(params[:tab])
    
    session[:dj_index_detail] = params[:detail] if %w{ thumbs table }.include?(params[:detail])
    session[:dj_index_detail] ||= 'table'
    
    respond_to do |format|
      format.html {
        case params[:tab]
          when 'author'
            sql_name = "COALESCE(NULLIF(authors.name_romaji, ''), NULLIF(authors.name_kakasi, ''))"
            # possibly lighter query:
            #   Author.select(Arel.sql "id, #{sql_name} AS name").where("id IN (SELECT author_id FROM authors_doujinshi)").
            @authors = Author.
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
            @circles = Circle.
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
            @folders   = rel.order(:file_folder).distinct.pluck(:file_folder)
            @doujinshi = rel.where(file_folder: params[:folder]).order(:name_kakasi) if params[:folder]
        end
      }# html
      
      format.ereader {
        rel = Doujin.where(category: params[:tab])
        
        @folders = rel.order(:file_folder).distinct.pluck(:file_folder)
        
        if params[:folder]
          @doujinshi = rel.
            where(file_folder: params[:folder]).
            order(Arel.sql "LOWER(COALESCE(NULLIF(name_romaji, ''), NULLIF(name_kakasi, '')))")
        end
      }# ereader
    end # respond_to
  end # index
  
  def show
    if params[:mcomix]
      system %Q| mcomix -f #{@doujin.file_path(full: true).shellescape} & |
      return render json: {ris: :ok}
    end
  
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
      format.epub {
        #TODO: ZIP2EPUB converting job
      }# epub
    end
  end # show
  
  def score
    @doujin.update(params.permit(:score)) ?
      redirect_to(@doujin, notice: "doujin score set") :
      redirect_to(@doujin, alert: "unable to update the score")
  end # score
  
  def read
    # TODO: online reading
  end # read

  # GET /doujinshi/1/edit
  def edit
  end

  # PATCH/PUT /doujinshi/1
  def update
    if @doujin.update(doujin_params)
      redirect_to @doujin, notice: "Doujin was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # DELETE /doujinshi/1
  def destroy
    @doujin.destroy
    redirect_to doujinshi_url, notice: "Doujin was successfully destroyed."
  end


  private # ____________________________________________________________________


  def set_doujin
    unless @doujin = Doujin.find_by(id: params[:id])
      return redirect_to(doujinshi_path, alert: "doujin [#{params[:id]}] not found!")
    end
  end

  def doujin_params
    params.require(:doujin).permit(:name, :name_romaji, :name_kakasi, :size, :checksum, :num_images, :num_files, :score, :file_name, :file_folder, :name_orig)
  end
end
