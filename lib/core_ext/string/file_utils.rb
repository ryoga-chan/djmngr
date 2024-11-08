module CoreExt::String::FileUtils
  RE_IMAGE_EXT = /\.(jpe*g|gif|png)$/i

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
    tr("^0-9", ' ').split(' ').   # consider numbers only
      map{|n| '%010d' % n.to_i }. # add zero padding
      push(self). # preserve the alphabetic order at the end
      join(',')
  end # to_sortable_by_numbers
end

String.send :include, CoreExt::String::FileUtils
