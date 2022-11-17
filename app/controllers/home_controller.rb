class HomeController < ApplicationController
  def index
    @stats = {
      dj:     Doujin.count,
      dj_fav: Doujin.where(favorite: true).count,
      dj_cat: Doujin.group(:category).select("category, COUNT(1) AS n").
                      inject({}){|h, d| h.merge d.category => d.n },
      todo:   ProcessIndexRefreshJob.entries.size,
      wip:    Dir[ File.join Setting['dir.sorting'], '*', 'info.yml' ].size,
      epub:   Dir[ Rails.root.join 'public', 'epub', '*.epub' ].size,
      mda:    Author.count,
      mdc:    Circle.count,
      mdt:    Theme.count,
    }
  @stats[:md_tot] = @stats[:mda]+@stats[:mdc]+@stats[:mdt]
  end # index
  
  def settings
    if request.post? && s = Setting.find_by(id: params[:id])
      s.update params.permit(:value)
      flash[:alert] = s.errors.full_messages if s.errors.any?
      return redirect_to home_settings_path
    end
  end # settings
end
