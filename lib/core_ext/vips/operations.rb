module CoreExt::Vips::Operations
  def self.included(base)
    base.extend ClassMethods
  end

  module ClassMethods
    def webp_cropped_thumb(buffer_or_img, width: 160, height: 240, padding: true)
      vips = buffer_or_img.is_a?(::Vips::Image) \
        ? buffer_or_img
        : new_from_buffer(buffer_or_img, '')

      im = ::ImageProcessing::Vips.source vips
      if padding
        im = vips.is_landscape? ?
          im.resize_to_fill(width, height, crop: :attention) :
          im.resize_and_pad(width, height, alpha: true)
      else
        im = im.resize_to_fit(width, height)
      end
      thumb = im.convert('webp').saver(quality: IMG_QUALITY_THUMB).call(save: false)

      { orig_width:   vips.width,
        orig_height:  vips.height,
        landscape:    vips.is_landscape?,
        width:        thumb.width,
        height:       thumb.height,
        #buffer:      thumb.webpsave_buffer,
        image:        thumb, }
    end # webp_cropped_thumb

    def is_landscape?(buffer_or_img)
      img = buffer_or_img.is_a?(Vips::Image) ? buffer_or_img : new_from_buffer(buffer_or_img, '')
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
    img_scaled.extract_area x_offset, 0, w, h   # `extract_area` also aliased as `crop`
  end # scale_and_crop_to_offset_perc

  # down/up-scale image: im.resize_to_fit(w, h).jpegsave_buffer(Q: IMG_QUALITY_RESIZE)
  def resize_to_fit(maxw, maxh) = resize([maxw.to_f/width, maxh.to_f/height].min)

  def downsize_to(dst_w = nil, dst_h = nil)
    dst_w, dst_h = dst_w.to_f, dst_h.to_f
    scale_w = dst_w / width  if dst_w > 0 && width  > dst_w
    scale_h = dst_h / height if dst_h > 0 && height > dst_h
    scale_p = [scale_w, scale_h].compact.min

    scale_p ? resize(scale_p) : self
  end # downsize_to
end

Vips::Image.send :include, CoreExt::Vips::Operations
