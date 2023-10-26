module ApplicationHelper
  B64_GIF_TRASPARENT = 'R0lGODlhAgADAPAAAAAAAAAAACH5BAEAAAAALAAAAAACAAMAAAIChF8AOw=='
  
  def is_ereader_browser?
    %w{ Kobo Kindle NOOK }.any?{|i| request.user_agent.include? i }
  end # is_ereader?
  
  def inline_image_tag(mime, b64_data, options = {})
    options[:src] = "data:#{mime};base64,#{b64_data}"
    tag :img, options, true
  end # inline_image_tag
  
  def trasparent_image_tag(options = {}) = inline_image_tag(:'image/gif', B64_GIF_TRASPARENT, options)
  
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
  
  def link_to_mangaupdates_search(label, term, html_options = {})
    link_to label, "https://www.mangaupdates.com/authors.html?#{ { search: term }.to_query }", html_options.merge(target: :_blank)
  end # link_to_mangaupdates_search
  
  def links_to_search_engines(term, html_options = {})
    [
      link_to_exhentai_search(    :XH, term, html_options.merge(title: 'search on Ex-Hentai'   )),
      link_to_ehentai_search(     :EH, term, html_options.merge(title: 'search on E-Hentai'    )),
      link_to_panda_chaika_search(:PD, term, html_options.merge(title: 'search on Panda.chaika')),
      link_to_nhentai_search(     :NH, term, html_options.merge(title: 'search on N-Hentai'    )),
      link_to_sukebei_search(     :SK, term, html_options.merge(title: 'search on Sukebei.nyaa')),
      link_to_mangaupdates_search(:MU, term, html_options.merge(title: 'search on MangaUpdates')),
    ].compact.join(' | ').html_safe
  end # links_to_search_engines
end
