module JapaneseLabels
  extend ActiveSupport::Concern
  
  included do
    def label_name_orig   = self.name.present?        ? self.name        : self.name_kana
    def label_name_romaji = self.name_romaji.present? ? self.name_romaji : self.name_kakasi
  end
end # JapaneseLabels
