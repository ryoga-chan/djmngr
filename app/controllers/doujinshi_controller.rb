class DoujinshiController < ApplicationController
  layout -> { return 'ereader' if request.format.to_sym == :ereader }
  
  before_action :set_doujin, only: %i[ show edit update destroy ]

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
    respond_to do |format|
      format.html
      format.ereader
      format.any(:webp, :jpg) {
        # estrai primo frame (al posto di: `webpmux -get frame 1 out.webp -o -`)
        fname = Rails.root.join('public', 'thumbs', "#{@doujin.id}.webp").to_s
        img = ImageProcessing::Vips.source(fname).call save: false
        data = request.format.to_sym == :webp ?
          img.webpsave_buffer(Q: 70, lossless: false, min_size: true) :
          img.jpegsave_buffer(Q: 70)
        return send_data(data, type: request.format.to_sym, disposition: :inline,
          filename: "#{@doujin.id}.#{request.format.to_sym}")
      }
    end
  end # show

  # GET /doujinshi/new
  def new
    @doujin = Doujin.new
  end

  # GET /doujinshi/1/edit
  def edit
  end

  # POST /doujinshi
  def create
    @doujin = Doujin.new(doujin_params)

    if @doujin.save
      redirect_to @doujin, notice: "Doujin was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
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
