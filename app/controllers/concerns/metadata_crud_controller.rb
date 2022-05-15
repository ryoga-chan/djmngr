module MetadataCrudController
  extend ActiveSupport::Concern
  
  included do
    before_action { @model = params[:controller].singularize.capitalize.constantize }
    before_action :set_record, only: %i[ show edit update destroy ]
  end # included

  def index
    @records = @model
    
    if params[:term].present?
      params[:by] = 'linear' unless %w{ linear sparse }.include?(params[:by])
      @records = @model.search(params[:term], search_method: params[:by])
    end
    
    if params[:letter].present?
      @records = @records.
        where("name_romaji LIKE :q OR name_kakasi LIKE :q", q: "#{params[:letter]}%")
    end
    
    @records = @records.
      order(Arel.sql "COALESCE(NULLIF(name_romaji, ''), NULLIF(name_kakasi, ''))").
      page(params[:page])#.per(10)
    
    render 'application/metadata/index'
  end # index
  
  def show = render('application/metadata/show')
  def edit = render('application/metadata/form')
  
  def new
    @record = @model.new name: params[:name]
    render('application/metadata/form')
  end # new
  
  def create
    @record = @model.new record_params
    if @record.save
      params[:wip_hash] ?
        redirect_to({controller: :process, action: :edit, id: params[:wip_hash], tab: :ident, term: @record.name}) :
        redirect_to({action: :show, id: @record.id}, notice: "#{@model.name} [#{params[:id]} / #{@record.name}] created")
    else
      render('application/metadata/form', status: :unprocessable_entity)
    end
  end # end
  
  def update
    @record.update(record_params) ?
      redirect_to({action: :show, id: @record.id}, notice: "#{@model.name} [#{params[:id]} / #{@record.name}] updated") :
      render('application/metadata/form', status: :unprocessable_entity)
  end # update
  
  def destroy
    @record.destroy ?
      redirect_to({action: :index}, notice: "#{@model.name} [#{params[:id]} / #{@record.name}] deleted") :
      redirect_to({action: :index}, alert:  "can't delete #{@model.name} [#{params[:id]} / #{@record.name}]")
  end # destroy
  
  def tags_lookup
    begin
      records = @model.none
      records = @model.search params[:term] if params[:term].present?
      records = records.select(:id, :name_romaji, :name_kakasi).limit(50)
      render json: {result: :ok, tags: records.map{|r| {id: r.id, label: r.label_name_latin}} }
    rescue
      render json: {result: :err, msg: $!.to_s }
    end
  end # tags_lookup
  
  
  private # ____________________________________________________________________
  
  
  def set_record
    unless @record = @model.find_by(id: params[:id])
      flash[:alert] = "#{@model.name} [#{params[:id]}] not found!"
      return redirect_to(action: :index)
    end
  end # set_record
  
  def record_params
    params.require(:record).permit \
      :name, :name_romaji, :name_kana, :name_kakasi, :favorite,
      :info, :aliases, :links, :doujinshi_org_id, :doujinshi_org_url,
      {author_ids: []}, {circle_ids: []}, {theme_ids: []}
  end # record_params
end
