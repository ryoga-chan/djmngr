class HomeController < ApplicationController
  # https://colorkit.co/palette/ffadad-ffd6a5-fdffb6-caffbf-9bf6ff-a0c4ff-bdb2ff-ffc6ff/
  # https://colorkit.co/palette/00202e-003f5c-2c4875-8a508f-bc5090-ff6361-ff8531-ffa600-ffd380/
  PALETTE = %w[ ffadad ffd6a5 fdffb6 caffbf 9bf6ff a0c4ff bdb2ff ffc6ff
                ffd380 ffa600 ff8531 ff6361 bc5090 8a508f 2c4875 003f5c 00202e ]

  def index
    @stats = {
      dj:         Doujin.count,
      dj_size:    Doujin.sum(:size),
      dj_fav:     Doujin.where(favorite: true).count,
      dj_cat:     Doujin.group(:category).
                    select("category, COUNT(1) AS n").
                    inject({}){|h, d| h.merge d.category => d.n },
      todo:       ProcessIndexRefreshJob.entries.size,
      todo_size:  ProcessableDoujin.sum(:size),
      wip:        Dir[ File.join Setting['dir.sorting'], '*', 'info.yml' ].size,
      epub:       Dir[ Rails.root.join 'public', 'epub', '*.epub' ].size,
      mda:        Author.count,
      mdc:        Circle.count,
      mdt:        Theme.count,
    }
    @stats[:md_tot] = @stats[:mda]+@stats[:mdc]+@stats[:mdt]

    tot_dj   = Doujin.count
    @scores  = Doujin.
      select("score, COUNT(id) AS n").
      group(:score).having("n > 0").
      order(score: :desc).
      inject({}) do |h, d|
        key  = d.score || :ND
        perc = (d.n.to_f / tot_dj).round 4
        h.merge key => { n: d.n, perc: perc }
      end

    @last_djs = Doujin.order(created_at: :desc).limit(12)

    # build css properties for the pie chart
    if request.format.html?
      cur_deg = 0
      @pie_slices_css = @scores.map.with_index do |pair, i|
        score, data = pair
        deg = (360 * data[:perc]).round
        deg = 360 - cur_deg if (cur_deg + deg) > 360 || i == (@scores.length - 1)
        "##{PALETTE[i]} #{cur_deg}deg #{cur_deg+=deg}deg"
      end
    end
  end # index

  def settings
    @page_title = :settings

    if request.post? && params[:setting].is_a?(Array)
      errors = []
      restart = false

      params[:setting].each do |p|
        s = Setting.find_by(id: p[:id])
        s.attributes = p.permit(:value)
        restart = true if s.key.start_with?('search_engine.') && s.value_changed?
        errors << s unless s.save
      end

      flash[:alert] = [] if errors.any?
      errors.each{|s| flash[:alert] += s.errors.full_messages.map{|m| "#{s.key}: #{m}"} }

      # restart application
      if restart
        flash[:notice] = "restarting application..."
        Thread.new { sleep 1; FileUtils.touch Rails.root.join('tmp', 'restart.txt').to_s }
      end

      redirect_to home_settings_path
    end
  end # settings
end
