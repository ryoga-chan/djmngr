class WsController < ApplicationController
  def ehentai = render json: Ws::EHentai.search(params[:term])
end
