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
  
  def links_to_search_engines(term, html_options = {})
    Setting.search_engines.map{|lbl, url|
      link_to lbl, "#{url}#{ { q: term }.to_query[2..-1] }", html_options.merge(target: :_blank)
    }.join(' | ').html_safe
  end # links_to_search_engines
end
