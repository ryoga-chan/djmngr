module CoreExt
  module Array
    module Utils
      # select 3 sets of `chunk_size` images (start/middle/end)
      def pages_preview(chunk_size:)
        if size > (chunk_size*3)
          gap = (size - chunk_size*3)/2 # number of images for a single gap
          pages = []
          pages.concat self[0...chunk_size]
          pages.concat self[gap+chunk_size, chunk_size]
          pages.concat self[(-chunk_size)..-1]
        else
          self
        end
      end # pages_preview
    end
  end
end

Array.send :include, CoreExt::Array::Utils
