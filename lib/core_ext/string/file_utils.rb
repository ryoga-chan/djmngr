module CoreExt
  module String
    module FileUtils
      # append a suffix to filename
      def add_suffix_to_filename(sfix)
        my_dir   = File.dirname  self
        my_ext   = File.extname  self
        my_name  = File.basename self, my_ext
        dst_name = "#{my_name}#{sfix}#{my_ext}"
        my_dir == '.' ? dst_name : File.join(my_dir, dst_name)
      end # add_suffix_to_filename
    end
  end
end

String.send :include, CoreExt::String::FileUtils
