module CoreExt::String::FileUtils
  RE_IMAGE_EXT = /\.(jpe*g|gif|png|webp)$/i
  SORTABLE_MAX = 10 # max number of numbers to consider for sorting
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

  def to_a_sortable_by_numbers
    nums = utf8_clean.
      tr("^0-9", ' ').split(' ').map{|n| n.to_i }.
      # prioritize by folder depth
      unshift(scrub.count(File::SEPARATOR))

    # consider only SORTABLE_MAX numbers at max
    nums.size <= SORTABLE_MAX \
      ? (SORTABLE_MAX - nums.size).times{ nums.push 0 }
      : nums.slice!(SORTABLE_MAX, 1_000)

    # preserve alphabetic order at last
    nums.push self
  end # to_a_sortable_by_numbers

  def slice_me!(s, l)
    slice! s, l
    self
  end # slice_me!

  def to_sortable_by_numbers
    to_a_sortable_by_numbers. # add zero padding
      map{|n| n.is_a?(Numeric) ? ('%010d' % n).slice_me!(10, 1_000) : n }.
      join #'|'
  end # to_sortable_by_numbers

  # from https://api.rubyonrails.org/classes/ActiveStorage/Filename.html#method-i-sanitized
  def to_sanitized_filename
    encode(Encoding::UTF_8, invalid: :replace, undef: :replace, replace: "�").
      strip.tr("\u{202E}%$|:;/<>?*\"\t\r\n\\", "_")
  end # to_sanitized_filename
end

String.send :include, CoreExt::String::FileUtils
