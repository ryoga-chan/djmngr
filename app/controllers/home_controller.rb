class HomeController < ApplicationController
  def index
  end # index
  
  def settings
    if request.post? && s = Setting.find_by(id: params[:id])
      s.update params.permit(:value, :notes)
      flash[:alert] = s.errors.full_messages if s.errors.any?
      return redirect_to home_settings_path
    end
  end # settings
end
