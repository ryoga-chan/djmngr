module MetadataCrudController
  extend ActiveSupport::Concern
  
  included do
    before_action { @model = params[:controller].singularize.capitalize.constantize }
    before_action :set_record, only: %i[ show edit update destroy ]
  end # included

  def index
    @records = @model
    
    if params[:term].present?
      params[:by] = 'linear' unless %{ linear sparse }.include?(params[:by])
      @records = @model.search(params[:term], search_method: params[:by])
    end
    
    if params[:letter].present?
      @records = @records.
        where("name_romaji LIKE :q OR name_kakasi LIKE :q", q: "#{params[:letter]}%")
    end
    
    @records = @records.
      order(Arel.sql "COALESCE(NULLIF(name_romaji, ''), NULLIF(name_kakasi, ''))").
      page(params[:page]).per(5)
    
    render 'application/metadata/index'
  end # index
  
  def show = render('application/metadata/show')
  def edit = render('application/metadata/form')
  
  def new
    @record = @model.new
    render('application/metadata/form')
  end # new
  
  def create
    @record = @model.new record_params
    @record.save ?
      redirect_to({action: :show, id: @record.id}, notice: "#{@model.name} [#{params[:id]}] created") :
      render('application/metadata/form', status: :unprocessable_entity)
  end # end
  
  def update
    @record.update(record_params) ?
      redirect_to({action: :show, id: @record.id}, notice: "#{@model.name} [#{params[:id]}] updated") :
      render('application/metadata/form', status: :unprocessable_entity)
  end # update
  
  def destroy
    @doujin.destroy ?
      redirect_to({action: :index}, notice: "#{@model.name} [#{params[:id]}] deleted") :
      redirect_to({action: :index}, alert:  "#{@model.name} [#{params[:id]}] NOT deleted")
  end # destroy
  
  
  private # ____________________________________________________________________
  
  
  def set_record
    unless @record = @model.find_by(id: params[:id])
      flash[:alert] = "record [#{params[:id]}] not found!"
      return redirect_to(action: :index)
    end
  end # set_record
  
  def record_params
    params.require(:record).permit \
      :name, :name_romaji, :name_kana, :name_kakasi, :favorite,
      :info, :aliases, :links, :doujinshi_org_id, :doujinshi_org_url
  end # record_params
end
