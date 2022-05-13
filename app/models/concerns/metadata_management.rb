module MetadataManagement
  extend ActiveSupport::Concern
  
  # https://stackoverflow.com/questions/28300354/rails-problems-with-validation-in-concern/28300860#28300860
  include ActiveModel::Validations
  
  included do
    validates :name, presence: true
    
    before_validation :sanitize_fields
    
    def sanitize_fields
      self.name_kakasi = name.to_romaji if name_changed? || name_kakasi.blank?
    end # sanitize_fields
  end
end # MetadataManagement
