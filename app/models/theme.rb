class Theme < ApplicationRecord
  has_and_belongs_to_many :authors, before_add: -> (t, a) {
    return unless t.authors.where(id: a.id).exists? # ensure uniqueness
    t.errors.add :base, "author already associated [#{a.id}: #{a.name}]"
    throw :abort
  }
  has_and_belongs_to_many :circles, before_add: -> (t, c) {
    return unless t.circles.where(id: c.id).exists? # ensure uniqueness
    t.errors.add :base, "circle already associated [#{c.id}: #{c.name}]"
    throw :abort
  }

  has_many   :children, class_name: 'Theme', inverse_of: :parent, foreign_key: 'parent_id'
  belongs_to :parent  , class_name: 'Theme', inverse_of: :children, optional: true
  
  include SearchJapaneseSubject
  include DoujinshiOrgReference
end
