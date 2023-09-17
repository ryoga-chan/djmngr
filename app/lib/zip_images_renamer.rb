module ZipImagesRenamer
  RENAME_METHODS = {
    "alphabetical index"                  => :alphabetical_index,
    "use numbers only"                    => :numbers_only,
    "filename to number"                  => :to_integer,
    "regexp \\1 to number"                => :regex_number,
    "regexp \\1 as prefix, \\2 as number" => :regex_pref_num,
    "regexp \\1 to number, \\2 as prefix" => :regex_num_pref,
    "full regexp replacement"             => :regex_replacement,
  }

  DEFAULT_METHOD = :numbers_only

  def self.rename(images, method = DEFAULT_METHOD, options = {})
    case method.to_sym
      when :alphabetical_index
        images.
          sort_by_method(:'[]', :src_path).
          each_with_index{|img, i| img[:dst_path] = "%04d#{File.extname img[:src_path]}" % (i+1) }
      
      when :numbers_only
        # create a sortable label
        images.each do |img|
          img[:alt_label]  = img[:src_path].tr("^0-9", ' ').split(' ').map{|n| '%010d' % n.to_i }.join(',')
          img[:alt_label] += img[:src_path] # preserve the alphabetic order at the end
        end
        rename_by_alt_label images
      
      when :to_integer
        images.each{|img| img[:dst_path] = "%04d#{File.extname img[:src_path]}" % img[:src_path].to_i }
      
      when :regex_number
        re = Regexp.new options[:rename_regexp]
        
        images.each do |img|
          img[:dst_path] = "%04d#{File.extname img[:src_path]}" %
                           img[:src_path].match(re)&.captures&.first.to_i
        end
      
      when :regex_pref_num, :regex_num_pref
        re = Regexp.new options[:rename_regexp]
        # create a sortable label
        invert_terms = options[:rename_with].to_sym == :regex_num_pref
        images.each do |img|
          prefix, num = img[:src_path].match(re)&.captures
          num, prefix = prefix, num if invert_terms
          img[:alt_label] = "#{prefix}-#{'%050d' % num.to_i}"
        end
        rename_by_alt_label images
      
      when :regex_replacement
        re = Regexp.new options[:rename_regexp]
        images.each{|img| img[:dst_path] = img[:src_path].sub re, options[:rename_regexp_repl] }
      
      else
        raise 'unknown renaming method'
    end # case
    
    # append filenames to dst_path
    if options[:keep_names].to_s == 'true'
      images.each_with_index do |img, i|
        ext  = File.extname  img[:dst_path]
        name = File.basename img[:dst_path], ext
        img[:dst_path] = "#{name}-#{img[:src_path].sub(/\.[^\.]+$/, ext).tr File::SEPARATOR, '_'}"
      end
    end
    
    images
  end # self.rename
  
  def self.rename_by_alt_label(images)
    images.
      sort_by_method(:'[]', :alt_label).
      each_with_index{|img, i| img[:dst_path] = "%04d#{File.extname img[:src_path]}" % (i+1) }
  end # self.rename_by_alt_label
end # ZipImagesRenamer
