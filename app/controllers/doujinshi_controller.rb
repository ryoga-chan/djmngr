class DoujinshiController < ApplicationController
  before_action :set_doujin, only: %i[ show edit update destroy ]

  # GET /doujinshi
  def index
    params[:tab] = 'author' unless %w{ author circle artbook magazine }.include?(params[:tab])
    
    rel = Doujin.where(category: params[:tab])
    @folders = rel.order(:file_folder).distinct.pluck(:file_folder)
    @doujinshi = rel.where(file_folder: params[:folder]).order(:name) if params[:folder]
  end

  # GET /doujinshi/1
  def show
    respond_to do |format|
      format.html
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
  end

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

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_doujin
      @doujin = Doujin.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def doujin_params
      params.require(:doujin).permit(:name, :name_romaji, :name_kakasi, :size, :checksum, :num_images, :num_files, :score, :file_name, :file_folder, :name_orig)
    end
end
