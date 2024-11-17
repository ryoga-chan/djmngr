module CoreExt::String::FileUtils
  RE_IMAGE_EXT = /\.(jpe*g|gif|png|webp)$/i

  UTF8_ENC_OPTIONS = { invalid: :replace, undef: :replace, replace: '_' }.freeze

  def is_image_filename? = encode(Encoding::UTF_8, **UTF8_ENC_OPTIONS).match?(RE_IMAGE_EXT)

  # append a suffix to filename
  def add_suffix_to_filename(sfix)
    my_dir   = File.dirname  self
    my_ext   = File.extname  self
    my_name  = File.basename self, my_ext
    dst_name = "#{my_name}#{sfix}#{my_ext}"
    my_dir == '.' ? dst_name : File.join(my_dir, dst_name)
  end # add_suffix_to_filename

  def to_sortable_by_numbers
    utf8_clean.
      tr("^0-9", ' ').split(' ').   # consider numbers only
      map{|n| '%010d' % n.to_i }. # add zero padding
      push(self). # preserve the alphabetic order at the end
      join(',')
  end # to_sortable_by_numbers
  
  # from https://api.rubyonrails.org/classes/ActiveStorage/Filename.html#method-i-sanitized
  def to_sanitized_filename
    encode(Encoding::UTF_8, invalid: :replace, undef: :replace, replace: "�").
      strip.tr("\u{202E}%$|:;/<>?*\"\t\r\n\\", "_")
  end # to_sanitized_filename
end

String.send :include, CoreExt::String::FileUtils
