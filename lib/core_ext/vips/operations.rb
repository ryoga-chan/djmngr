module CoreExt
  module Vips
    module Operations
      def scale_and_crop_to_offset_perc(w, h, p)
        raise 'percentage not in 0..100' unless (0..100).include?(p)
        raise 'not a landscape image' if self.width <= self.height
        
        # https://www.libvips.org/API/current/libvips-resample.html#vips-thumbnail
        # the first parameter is the width of a square of size `width`x`width`
        # and we want a max height of `h`, so:
        #   x / 360 = image_w / image_h  ==>  x = image_w*360/image_h
        img_scaled = self.thumbnail_image self.width*h/self.height, height: h

        # https://stackoverflow.com/questions/10853119/chop-image-into-tiles-using-vips-command-line/11098420#11098420
        x_offset   = (img_scaled.width - w) * p / 100
        img_scaled.extract_area x_offset, 0, w, h
      end
    end
  end
end

Vips::Image.send :include, CoreExt::Vips::Operations
