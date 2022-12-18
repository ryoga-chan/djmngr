class ShelvesController < ApplicationController
  before_action :set_doujin_list_detail, only: %i[ show ]
  before_action :set_record, only: %i[ show edit update destroy ]

  def index = @records = Shelf.order(created_at: :desc).page(params[:page]).per(10)
  
  def show
    @doujinshi = @record.doujinshi.order(:position)
  
    respond_to do |format|
      format.ereader
      format.json {
        ExternalProgramRunner.run params[:run],
          @doujinshi.map{|d| d.file_path },
          chdir: Setting['dir.sorted']
        render json: {ris: :ok}
      }#json
    end
  end # show

  def edit; end

  def update
    @record.update(record_params) ?
      redirect_to({action: :index}, notice: "Shelf [#{@record.id} / #{@record.name}] updated") :
      render(:edit, status: :unprocessable_entity)
  end # edit

  def destroy
    @record.destroy ?
      redirect_to({action: :index}, notice: "Shelf [#{@record.id} / #{@record.name}] deleted") :
      redirect_to({action: :index}, alert:  "can't delete Shelf [#{@record.id} / #{@record.name}]")
  end


  private
  
  
  # Use callbacks to share common setup or constraints between actions.
  def set_record
    unless @record = Shelf.find_by(id: params[:id])
      flash[:alert] = "Shelf [#{params[:id]}] not found!"
      return redirect_to(action: :index)
    end
  end # set_record

  def record_params
    params.require(:record).
      permit(:name, doujinshi_shelves_attributes: [:id, :position, :_destroy])
  end # record_params
end
