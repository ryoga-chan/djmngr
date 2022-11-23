class Shelf < ApplicationRecord
  has_many :doujinshi_shelves, dependent: :delete_all
  has_many :doujinshi, through: :doujinshi_shelves
  
  accepts_nested_attributes_for :doujinshi_shelves, allow_destroy: true
end
