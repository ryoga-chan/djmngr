class WsController < ApplicationController
  def to_romaji = render plain: params[:s].to_s.to_romaji.strip
  def ehentai   = render json: Ws::EHentai.search(params[:term])
  def dl_image  = render json: ImageToDummyArchive.download(params)
end
