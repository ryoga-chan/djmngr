module CoreExt
  module String
    module Kakasi
      KAKASI_MAXLENGTH   = 10_000
      KAKASI_OPTIONS     = '-Ha -Ka -Ja -Ea -ka -ja -ga -s -c -rhepburn'.freeze
      KAKASI_ENC_OPTIONS = { invalid: :replace, undef: :replace, replace: '_' }.freeze
      
      # -p = alt readings, -f = furigana mode
      def to_romaji(alt_readings: false, furigana_mode: false)
        kakasi_opts  = KAKASI_OPTIONS.dup
        kakasi_opts += ' -p' if alt_readings
        kakasi_opts += ' -f' if furigana_mode
        
        ::Kakasi.kakasi(
          kakasi_opts,
          self[0..KAKASI_MAXLENGTH].
            # fix UTF-8 to Windows-31J (Encoding::UndefinedConversionError)
            encode(Encoding::CP932, **KAKASI_ENC_OPTIONS)
        ).encode(Encoding::UTF_8, **KAKASI_ENC_OPTIONS) # reencode to UTF8 for further processing
      end # to_romaji
    end
  end
end

String.send :include, CoreExt::String::Kakasi
