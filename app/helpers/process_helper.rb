module ProcessHelper
  def thumbnail_tag(fname, options = {})
    File.exist?(fname) ? # Marcel::MimeType.for extension: :jpg
      inline_image_tag(:'image/jpeg', Base64.encode64(File.read fname), options) :
      :MISS
  end # thumbnail_tag
end
