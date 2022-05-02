class Author < ApplicationRecord
  has_and_belongs_to_many :circles, before_add: -> (a, c) {
    return unless a.circles.where(id: c.id).exists? # ensure uniqueness
    a.errors.add :base, "circle already associated [#{c.id}: #{c.name}]"
    throw :abort
  }
  has_and_belongs_to_many :themes, before_add: -> (a, t) {
    return unless a.themes.where(id: t.id).exists? # ensure uniqueness
    a.errors.add :base, "theme already associated [#{t.id}: #{t.name}]"
    throw :abort
  }
  has_and_belongs_to_many :doujinshi, before_add: -> (a, d) {
    return unless a.doujinshi.where(id: d.id).exists? # ensure uniqueness
    a.errors.add :base, "doujin already associated [#{d.id}: #{d.file_path}]"
    throw :abort
  }
  
  include JapaneseLabels
  include SearchJapaneseSubject
  include DoujinshiOrgReference
  include FavoriteManagement
end
