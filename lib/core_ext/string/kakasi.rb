module CoreExt::String::Kakasi
  KAKASI_MAXLENGTH   = 10_000
  KAKASI_OPTIONS     = '-Ha -Ka -Ja -Ea -ka -ja -ga -s -c -rhepburn'.freeze
  KAKASI_ENC_OPTIONS = { invalid: :replace, undef: :replace, replace: '_' }.freeze

  RE_UNIHAN = /\p{Han}|\p{Hiragana}|\p{Katakana}/

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
    ).encode(Encoding::UTF_8, **KAKASI_ENC_OPTIONS). # reencode to UTF8 for further processing
    gsub(/\(kigou\)/, '-') # symbol -- https://jlearn.net/search/kigou?source=dictionary
  end # to_romaji

  # detect if the sting contains a "Unified Han charset" character (hanzi/kanji/hanja/chuhan)
  # Reference:
  #   1. https://stackoverflow.com/questions/22339826/check-if-a-string-contains-a-character-in-a-unicode-range-using-ruby/22340250#22340250
  #   2. https://en.wikipedia.org/wiki/Han_unification
  #        Han characters are a feature shared in common by written Chinese (hanzi),
  #        Japanese (kanji), Korean (hanja) and Vietnamese (chữ Hán).
  #   3. https://stackoverflow.com/questions/43418812/check-whether-a-string-contains-japanese-chinese-characters/43419070#43419070
  #   4. https://ruby-doc.org/3.2.0/regexp_rdoc.html#label-Character+Properties
  def has_unihan? = self.match?(RE_UNIHAN)
end

String.send :include, CoreExt::String::Kakasi
