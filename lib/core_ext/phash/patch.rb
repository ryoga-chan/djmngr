module CoreExt::Phash::Patch
  module ::Phash
    # TODO: remove this method once issue #2 is completed:
    #   allow fingerprinting a Vips::Image object
    #   https://github.com/khasinski/phash-rb/issues/2
    def self.fingerprint(path_or_img)
      img = path_or_img.is_a?(::Vips::Image) \
        ? path_or_img
        : ::Vips::Image.new_from_file(path_or_img)

      # drop alpha channel
      img = img.flatten(background: 255) if img.has_alpha?

      #Y = (66*R + 129*G + 25*B + 128)/256 + 16
      img = img * [66.0 / 256, 129.0 / 256, 25.0 / 256]
      r, g, b = img.bandsplit
      img = r + g + b + 16.5

      mask = ::Vips::Image.new_from_array([[1.0] * 7] * 7)
      img = img.colourspace("grey16")
      img = img.conv(mask)
      mat = sample(img)
      dct = ph_dct_matrix
      dct_t = dct.transpose

      out = dct * mat * dct_t

      sub = out.minor(1..8, 1..8).to_a.flatten
      median = sub.sort[31..32].sum / 2

      sub.reverse.map {|i| i > median ? 1 : 0 }.join.to_i(2)
    end # self.fingerprint
  end # module ::Phash
end
