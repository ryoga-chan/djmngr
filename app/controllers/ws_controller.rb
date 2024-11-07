class WsController < ApplicationController
  def ehentai = render json: Ws::EHentai.search(params[:term])
  
  def to_romaji = render plain: params[:s].to_s.to_romaji.strip
end
