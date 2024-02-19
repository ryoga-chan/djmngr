module JapaneseLabels
  extend ActiveSupport::Concern

  included do
    def label_name_kanji = name.present? ? name : try(:name_kana)

    def label_name_latin
      return name_romaji if name_romaji.present?
      return name_eng    if try(:name_eng).present?
      name_kakasi
    end
  end
end # JapaneseLabels
