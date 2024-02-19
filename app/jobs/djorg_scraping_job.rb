class DjorgScrapingJob < ApplicationJob
  queue_as :scrape

# # anziche' fare una procedura ricorsiva, facciamo un elenco di funzioni da chiamare
# dl_actions = [[dl_xxxxxx, x_id]]
# while pair = dl_actions.pop()
#   self.send *pair
# end
#
# # - tramite i dati scaricati crea i records (authors, circles, themes)
# # - imposta alias se richiesto nei parametri => update! doujinshi_org_aka_id: $1.to_i
# # - crea le relazioni tra i records (model.find_by_doujinshi_org_id ...)
#
# #-------------------------------------------------------------------------------
#
# * dl_author(x)
#   - parsed[:authors].include?(x_id) ? return : parsed[:authors].push(x_id)
#   - scarica pagina author
#   - segna ids+url dei circles mancanti: info[:author_circles].merge x_id => [{c_id => c_url, ...}]
#   - segna ids+url dei themes  mancanti: info[:author_themes ].merge x_id => [{t_id => t_url, ...}]
#   - per ogni circle mancante: dl_circle(i)
#   - per ogni theme  mancante: dl_theme(i)
#
# * dl_circle(x)
#   - parsed[:circles].include?(x_id) ? return : parsed[:circles].push(x_id)
#   - scarica pagina circle
#   - segna ids+url dei authors mancanti: info[:circle_authors].merge x_id => [{c_id => c_url, ...}]
#   - segna ids+url dei themes  mancanti: info[:circle_themes ].merge x_id => [{t_id => t_url, ...}]
#   - per ogni author mancante: dl_author(i)
#   - per ogni theme  mancante: dl_theme(i)
#
# * dl_theme(x)
#   - parsed[:themes].include?(x_id) ? return : parsed[:themes].push(x_id)
#   - scarica pagina theme
#   - segna ids+url del theme padre mancante: info[:theme_parents].merge x_id => [{p_id => p_url}]
#   - se theme padre mancante: dl_theme(p)

  def self.info_file_path(model_name, url)
    # url format: /browse/(author|circle|contents)/NUMERIC_ID/item_name/
    raise 'unknown item type' unless %w[author circle theme].include?(model_name)
    raise 'no ID found' unless id = url.match(/\/browse\/[^\/]+\/([0-9]+)\/.+/)&.captures&.first
    Rails.root.join('tmp', "#{model_name}-#{id}", 'info.yml').to_s
  end # self.info_file_path

  def self.create_info_file(model_name, url)
    fname = self.class.info_file_path model_name, url
    FileUtils.mkdir_p File.dirname(fname)
    FileUtils.touch   fname
    fname
  end # self.create_info_file

  def perform(model_name, url, options = {})
    raise "TODO"
    # "#{::DoujinshiOrgReference::DOUJINSHI_ORG_BASE_URL}#{req.headers[:location]}"

    #info_fname = self.class.create_info_file
    @info = {}

    # use a queue instead of recursion for informative purposes
    @dl_actions, @urls_done = [ ["dl_#{model_name}", url] ], []
    while action_params = @dl_actions.pop
      next if @urls_done.incluhde?(action_params[1])
      @urls_done << action_params[1]
      send *action_params
    end

    #File.open(info_fname, 'w'){|f| f.puts @info.to_yaml }
  end # perform


  private # ____________________________________________________________________


  def dl_author(url)
#   - scarica pagina author
#   - segna ids+url dei circles mancanti: info[:author_circles].merge x_id => [{c_id => c_url, ...}]
#   - segna ids+url dei themes  mancanti: info[:author_themes ].merge x_id => [{t_id => t_url, ...}]
#   - per ogni circle mancante: dl_circle(i)
#   - per ogni theme  mancante: dl_theme(i)
  end # dl_author
end
