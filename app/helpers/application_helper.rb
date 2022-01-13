module ApplicationHelper
  def inline_image_tag(mime, b64_data, options = {})
    options[:src] ="data:#{mime};base64,#{b64_data}"
    tag :img, options, true
  end # inline_image_tag
end
