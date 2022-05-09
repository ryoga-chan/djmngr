module ApplicationHelper
  def is_ereader?
    return true if request.user_agent.include?('Kobo')
    false
  end # is_ereader?
  
  def inline_image_tag(mime, b64_data, options = {})
    options[:src] = "data:#{mime};base64,#{b64_data}"
    tag :img, options, true
  end # inline_image_tag
  
  def link_to_exhentai_search(term, html_options = {})
    link_to term, "https://exhentai.org/?#{ {f_search: term}.to_query }", html_options.merge(target: :_blank)
  end # link_to_exhentai_search
end
