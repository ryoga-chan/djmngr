module ApplicationHelper
  def is_ereader_browser?
    %w{ Kobo Kindle NOOK }.any?{|i| request.user_agent.include? i }
  end # is_ereader?
  
  def inline_image_tag(mime, b64_data, options = {})
    options[:src] = "data:#{mime};base64,#{b64_data}"
    tag :img, options, true
  end # inline_image_tag
  
  def link_to_exhentai_search(label, term, html_options = {})
    link_to label, "https://exhentai.org/?#{ {f_search: term}.to_query }", html_options.merge(target: :_blank)
  end # link_to_exhentai_search
  
  def link_to_ehentai_search(label, term, html_options = {})
    link_to label, "https://e-hentai.org/?#{ {f_search: term}.to_query }", html_options.merge(target: :_blank)
  end # link_to_ehentai_search
  
  def link_to_panda_chaika_search(label, term, html_options = {})
    p = { title: term, sort: :public_date, asc_desc: :desc, view: :cover }
    link_to label, "https://panda.chaika.moe/search/?#{p.to_query}", html_options.merge(target: :_blank)
  end # link_to_panda_chaika_search
  
  def link_to_nhentai_search(label, term, html_options = {})
    link_to label, "https://nhentai.net/search/?#{ { q: term }.to_query }", html_options.merge(target: :_blank)
  end # link_to_nhentai_search
  
  def link_to_sukebei_search(label, term, html_options = {})
    link_to label, "https://sukebei.nyaa.si/?#{ { q: term }.to_query }", html_options.merge(target: :_blank)
  end # link_to_sukebei_search
  
  def links_to_search_engines(term, html_options = {})
    [
      link_to_exhentai_search(:XEH, term, html_options),
      link_to_ehentai_search(:GEH, term, html_options),
      link_to_panda_chaika_search(:PND, term, html_options),
      link_to_nhentai_search(:NH, term, html_options),
      link_to_sukebei_search(:SUK, term, html_options),
    ].join(' | ').html_safe
  end # links_to_search_engines
end
