module ProcessHelper
  def thumbnail_tag(fname)
    File.exist?(fname) ? # Marcel::MimeType.for extension: :jpg
      inline_image_tag(:'image/jpeg', Base64.encode64(File.read fname)) :
      :MISS
  end # thumbnail_tag
end
