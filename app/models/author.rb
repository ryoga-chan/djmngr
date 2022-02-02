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

  def self.search_by_name(term, limit: 30)
    # NOTE: sqlite LIKE is case insensitive! ==> https://www.sqlite.org/optoverview.html#the_like_optimization
    query = <<~SQL
      SELECT
          *
        , CASE INSTR(LOWER(name             ), :term_d ) WHEN 0 THEN 0 ELSE 1.0 END +
          CASE INSTR(LOWER(name_kana        ), :term_d ) WHEN 0 THEN 0 ELSE 1.0 END +
          CASE INSTR(LOWER(name_romaji      ), :term_d ) WHEN 0 THEN 0 ELSE 1.0 END +
          CASE INSTR(LOWER(name_kakasi      ), :term_dk) WHEN 0 THEN 0 ELSE 1.0 END +
          CASE INSTR(LOWER(aliases          ), :term_d ) WHEN 0 THEN 0 ELSE 0.5 END +
          CASE INSTR(LOWER(doujinshi_org_url), :term_d ) WHEN 0 THEN 0 ELSE 0.5 END
          AS weigth
      FROM #{self.table_name}
      WHERE name              LIKE :term_q
         OR name_kana         LIKE :term_q
         OR name_romaji       LIKE :term_q
         OR name_kakasi       LIKE :term_qk
         OR aliases           LIKE :term_q
         OR doujinshi_org_url LIKE :term_q
      ORDER BY weigth DESC, name_romaji, id DESC
      LIMIT :limit
    SQL
    
    term_d = term.downcase
    term_q = "%#{term}%"
    query_params = { term_d: term_d, term_dk: term_d.to_romaji,
                     term_q: term_q, term_qk: term_q.to_romaji, limit: limit }
    
    self.find_by_sql [query, query_params]
  end # self.search_by_name
end
