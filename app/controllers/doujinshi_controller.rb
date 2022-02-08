class DoujinshiController < ApplicationController
  before_action :set_doujin, only: %i[ show edit update destroy ]

  # GET /doujinshi
  def index
    @doujinshi = Doujin.all
  end

  # GET /doujinshi/1
  def show
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
      params.require(:doujin).permit(:name, :name_romaji, :name_kakasi, :size, :checksum, :num_images, :num_files, :score, :path, :name_orig)
    end
end
