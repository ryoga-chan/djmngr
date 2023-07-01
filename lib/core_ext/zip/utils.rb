module CoreExt
  module Zip
    module Utils      
      def image_entries(sort: false)
        list = entries.select{|e| e.file? && e.name =~ RE_IMAGE_EXT }
        sort ? list.sort_by_method(:name) : list
      end # image_entries
    end
  end
end

Zip::File.send :include, CoreExt::Zip::Utils
