module CoreExt::Vips::ImageHashing
  def self.included(base)
    base.extend ClassMethods
  end

  module ClassMethods
    def fingerprint_idhash(buf: nil, path: nil, img: nil, fmt: :db)
      h = ::DHashVips::IDHash.fingerprint fingerprint_load_image(buf, path, img)
      case fmt
        when :db, :hex then h.to_s(16).rjust(64, '0')
        else h
      end
    end # fingerprint_idhash

    def fingerprint_phash(buf: nil, path: nil, img: nil, fmt: :db)
      Tempfile.create(%w[phash- .webp], Setting['dir.sorting']) do |f|
        fingerprint_load_image(buf, path, img).webpsave f.path
        h = Kernel.suppress_output{ ::Phashion::Image.new(f.path).fingerprint }
        case fmt
          when :db  then [h].pack('Q').unpack('q').first
          when :hex then h.to_s(16).rjust(16, '0')
          else h
        end
      end
    end # fingerprint_phash

    def fingerprints(buf: nil, path: nil, img: nil, fmt: :db)
      img = fingerprint_load_image buf, path, img
      { phash:  fingerprint_phash(img: img, fmt: fmt),
        idhash: fingerprint_idhash(img: img, fmt: fmt) }
    end # fingerprint

    private

    def fingerprint_load_image(buf = nil, path = nil, img = nil)
      case
        when buf  then ::Vips::Image.new_from_buffer(buf, '')
        when path then ::Vips::Image.new_from_file(path)
        else img
      end
    end # fingerprint_load_image
  end # ClassMethods

  def fingerprint_phash(fmt: :db)  = self.class.fingerprint_phash(img: self, fmt: fmt)
  def fingerprint_idhash(fmt: :db) = self.class.fingerprint_idhash(img: self, fmt: fmt)
  def fingerprints(fmt: :db)       = self.class.fingerprints(img: self, fmt: fmt)
end

Vips::Image.send :include, CoreExt::Vips::ImageHashing
