module MetadataManagement
  extend ActiveSupport::Concern
  
  # https://stackoverflow.com/questions/28300354/rails-problems-with-validation-in-concern/28300860#28300860
  include ActiveModel::Validations
  
  included do
    before_validation :sanitize_fields
    validates :name, presence: true
    
    # TODO: do not delete record if associated to someone
    #       ask confirmation and remove associations
    #before_destroy :check_if_associated

    
    def sanitize_fields
      self.name_kakasi = name.to_romaji if name_changed?
    end # sanitize_fields
  end
end # MetadataManagement
