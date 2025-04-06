module CoreExt::Vips::ImageHashing
  def self.included(base)
    base.extend ClassMethods
  end

  module ClassMethods
    ## important difference
    #def fingerprint_idhash(buf: nil, path: nil, img: nil, fmt: :db)
    #  h = ::DHashVips::IDHash.fingerprint fingerprint_load_image(buf, path, img)
    #  case fmt
    #    when :db, :hex then h.to_s(16).rjust(64, '0')
    #    else h
    #  end
    #end # fingerprint_idhash

    # perceptual
    def fingerprint_phash(buf: nil, path: nil, img: nil, fmt: :db)
      Tempfile.create(%w[phash- .webp], Setting['dir.sorting']) do |f|
        # TODO: see lib/core_ext/phash/patch.rb
        image = fingerprint_load_image(buf, path, img)#.webpsave f.path
        h = Phash::Image.new(image).fingerprint #(f.path).fingerprint
        case fmt
          when :db  then [h].pack('Q').unpack('q').first
          when :hex then h.to_s(16).rjust(16, '0')
          else h
        end
      end
    end # fingerprint_phash

    # spatial distribution
    # https://stackoverflow.com/questions/36524206/is-possible-to-detect-if-two-images-are-the-same-using-ruby-vips8#36549563
    def fingerprint_sdhash(buf: nil, path: nil, img: nil, fmt: :db)
      image = fingerprint_load_image(buf, path, img).colourspace("b-w")
      image = image.shrink(image.width / 8, image.height / 8)
      avg = image.avg
      h = image.width.times.inject([]){|bits, c|
        image.height.times.inject(bits){|bits, r|
          bits.push(image.getpoint(c, r)[0] > avg ? 1 : 0)
        }
      }.join.to_i(2)
      case fmt
        when :db  then [h].pack('Q').unpack('q').first
        when :hex then h.to_s(16).rjust(64, '0')
        else h
      end
    end # fingerprint_sdhash

    def fingerprints(buf: nil, path: nil, img: nil, fmt: :db)
      img = fingerprint_load_image buf, path, img
      { phash:  fingerprint_phash(img: img, fmt: fmt),
        sdhash: fingerprint_sdhash(img: img, fmt: fmt) }
    end # fingerprint

    private

    def fingerprint_load_image(buf = nil, path = nil, img = nil)
      image = case
        when buf  then ::Vips::Image.new_from_buffer(buf, '')
        when path then ::Vips::Image.new_from_file(path)
        else img
      end

      return image.flatten(background: 255) if image.has_alpha?

      image
    end # fingerprint_load_image
  end # ClassMethods

  def fingerprint_phash(fmt: :db)  = self.class.fingerprint_phash(img: self, fmt: fmt)
  def fingerprint_sdhash(fmt: :db) = self.class.fingerprint_sdhash(img: self, fmt: fmt)
  def fingerprints(fmt: :db)       = self.class.fingerprints(img: self, fmt: fmt)
end

Vips::Image.send :include, CoreExt::Vips::ImageHashing
