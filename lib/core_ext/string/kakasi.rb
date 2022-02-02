module CoreExt
  module String
    module Kakasi
      KAKASI_MAXLENGTH   = 10_000
      KAKASI_OPTIONS     = '-Ha -Ka -Ja -Ea -ka -ja -ga -s -c -rhepburn'
      KAKASI_ENC_OPTIONS = { invalid: :replace, undef: :replace, replace: '_' }
      
      def to_romaji(kakasi_opts = [])
        ::Kakasi.kakasi(
          "#{KAKASI_OPTIONS} #{kakasi_opts.join ' '}",
          self[0..KAKASI_MAXLENGTH].
            # fix UTF-8 to Windows-31J (Encoding::UndefinedConversionError)
            encode(Encoding::CP932, **KAKASI_ENC_OPTIONS)
        ).encode(Encoding::UTF_8, **KAKASI_ENC_OPTIONS) # reencode to UTF8 for further processing
      end # to_romaji
    end
  end
end

String.send :include, CoreExt::String::Kakasi
