module CoreExt
  module Vips
    module Operations
      def self.included(base)
        base.extend ClassMethods
      end
      
      module ClassMethods
        def webp_cropped_thumb(buffer_or_img, buffer_fname: 'a.jpg', width: 160, height: 240)
          vips = buffer_or_img.is_a?(::Vips::Image) ? buffer_or_img : new_from_buffer(buffer_or_img, buffer_fname)
          im = ::ImageProcessing::Vips.source vips
          im = vips.is_landscape? ?
            im.resize_to_fill(width, height, crop: :attention) :
            im.resize_and_pad(width, height, alpha: true)
          {
            orig_width:   vips.width,
            orig_height:  vips.height,
            landscape:    vips.is_landscape?,
            buffer:       im.convert('webp').saver(quality: 70).call(save: false).webpsave_buffer,
          }
        end # webp_cropped_thumb
        
        def is_landscape?(buffer_or_img, buffer_fname: 'a.jpg')
          img = buffer_or_img.is_a?(Vips::Image) ? buffer_or_img : new_from_buffer(buffer_or_img, buffer_fname)
          img.is_landscape?
        end # is_landscape?
      end # ClassMethods
      
      def is_landscape? = width > height
      
      def scale_and_crop_to_offset_perc(w, h, p)
        raise 'percentage not in 0..100' unless (0..100).include?(p)
        raise 'not a landscape image' if self.width <= self.height
        
        # https://www.libvips.org/API/current/libvips-resample.html#vips-thumbnail
        # the first parameter is the width of a square of size `width`x`width`
        # and we want a max height of `h`, so:
        #   x / 360 = image_w / image_h  ==>  x = image_w*360/image_h
        square_side = (self.width.to_f*h/self.height).ceil
        img_scaled = self.thumbnail_image square_side, height: h

        # https://stackoverflow.com/questions/10853119/chop-image-into-tiles-using-vips-command-line/11098420#11098420
        x_offset   = ((img_scaled.width - w) * p.to_f / 100).to_i
        img_scaled.extract_area x_offset, 0, w, h
      end # scale_and_crop_to_offset_perc
    end
  end
end

Vips::Image.send :include, CoreExt::Vips::Operations
