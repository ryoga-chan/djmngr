module ProcessHelper
  def thumbnail_tag(fname, options = {})
    File.exist?(fname) ? # Marcel::MimeType.for extension: :webp
      inline_image_tag(:'image/webp', Base64.encode64(File.read fname), options) :
      :MISS
  end # thumbnail_tag
end
