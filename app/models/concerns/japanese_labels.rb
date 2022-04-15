module JapaneseLabels
  extend ActiveSupport::Concern
  
  DOUJINSHI_ORG_BASE_URL = 'https://www.doujinshi.org'.freeze

  included do
    def label_name_orig   = self.name.present?        ? self.name        : self.name_kana
    def label_name_romaji = self.name_romaji.present? ? self.name_romaji : self.name_kakasi
  end

  #class_methods do
  #end
end # JapaneseLabels
