class Circle < ApplicationRecord
  has_and_belongs_to_many :authors, before_add: -> (c, a) {
    return unless c.authors.where(id: a.id).exists? # ensure uniqueness
    c.errors.add :base, "author already associated [#{a.id}: #{a.name}]"
    throw :abort
  }
  has_and_belongs_to_many :themes, before_add: -> (c, t) {
    return unless c.themes.where(id: t.id).exists? # ensure uniqueness
    c.errors.add :base, "theme already associated [#{t.id}: #{t.name}]"
    throw :abort
  }

  include JapaneseLabels
  include SearchJapaneseSubject
  include DoujinshiOrgReference
end
