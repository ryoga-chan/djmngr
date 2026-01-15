module ProcessHelper
  def thumbnail_tag(fname, options = {})
    File.exist?(fname) ? # Marcel::MimeType.for extension: :webp
      inline_image_tag(:'image/webp', Base64.encode64(File.binread fname), options) :
      :MISS
  end # thumbnail_tag

  # highlight multiple spaces where present
  def hl_multispace(str)
    h(str).gsub(/( {2,})/) do |m|
      %Q(<span class="has-background-warning">#{'&nbsp;' * m.size}</span>)
    end.html_safe
  end # hl_multispace
end
