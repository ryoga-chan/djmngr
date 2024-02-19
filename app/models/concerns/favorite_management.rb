module FavoriteManagement
  extend ActiveSupport::Concern

  # https://stackoverflow.com/questions/28300354/rails-problems-with-validation-in-concern/28300860#28300860
  include ActiveModel::Validations

  included do
    before_validation :set_faved_at, on: :update


    private # __________________________________________________________________


    def set_faved_at
      self.faved_at = Time.now if favorite? && favorite_changed?
    end # set_faved_at
  end
end # FavoriteManagement
