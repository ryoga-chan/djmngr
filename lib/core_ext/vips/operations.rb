module CoreExt
  module Vips
    module Operations
      def scale_and_crop_to_offset_perc(w, h, p)
        raise 'percentage not in 0..100' unless (0..100).include?(p)
        
        # https://www.libvips.org/API/current/libvips-resample.html#vips-thumbnail
        img_scaled = self.thumbnail_image(self.height*w/h, height: h)

        # https://stackoverflow.com/questions/10853119/chop-image-into-tiles-using-vips-command-line/11098420#11098420
        crop_width = (img_scaled.height*w/h).to_i
        x_offset   = (img_scaled.width - crop_width) * p / 100
        img_scaled.extract_area x_offset, 0, crop_width, img_scaled.height
      end
    end
  end
end

Vips::Image.send :include, CoreExt::Vips::Operations
