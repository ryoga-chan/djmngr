module JapaneseLabels
  extend ActiveSupport::Concern
  
  included do
    def label_name_kanji = self.name.present?        ? self.name        : self.try(:name_kana)
    def label_name_latin = self.name_romaji.present? ? self.name_romaji : self.name_kakasi
  end
end # JapaneseLabels
