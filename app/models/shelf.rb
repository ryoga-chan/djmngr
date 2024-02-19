class Shelf < ApplicationRecord
  has_many :doujinshi_shelves, dependent: :delete_all
  has_many :doujinshi, through: :doujinshi_shelves

  accepts_nested_attributes_for :doujinshi_shelves, allow_destroy: true

  after_save :update_num_images

  validates_length_of :name, minimum: 3

  def update_num_images
    update_columns num_images: doujinshi.pluck(:num_images).sum
  end # update_num_images

  def add_doujin(doujin_id)
    self.doujin_ids += [doujin_id]
    update_num_images
  end # add_doujin

  def rm_doujin(doujin_id)
    self.doujin_ids -= [doujin_id]
    update_num_images
  end # rm_doujin
end
