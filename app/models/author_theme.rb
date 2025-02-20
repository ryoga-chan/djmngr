class AuthorTheme < ApplicationRecord
  belongs_to :author
  belongs_to :theme
end
