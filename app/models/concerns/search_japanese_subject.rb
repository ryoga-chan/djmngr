module SearchJapaneseSubject
  extend ActiveSupport::Concern

  #included do
  #end

  class_methods do
    def search_by_name(term, limit: 10)
      return self.where("1 <> 1") if term.to_s.blank?
      
      # NOTE: sqlite LIKE is case insensitive! => we can skip LOWER() to speed up WHERE
      # https://www.sqlite.org/optoverview.html#the_like_optimization
      query = <<~SQL
        SELECT
            *
          , CASE LOWER(name                   ) WHEN :term_d      THEN 1 ELSE 0   END +
            CASE LOWER(name_kana              ) WHEN :term_d      THEN 1 ELSE 0   END +
            CASE LOWER(name_romaji            ) WHEN :term_d      THEN 1 ELSE 0   END +
            CASE LOWER(name_kakasi            ) WHEN :term_dk     THEN 1 ELSE 0   END +
            CASE INSTR(LOWER(name             ), :term_d ) WHEN 0 THEN 0 ELSE 0.3 END +
            CASE INSTR(LOWER(name_kana        ), :term_d ) WHEN 0 THEN 0 ELSE 0.3 END +
            CASE INSTR(LOWER(name_romaji      ), :term_d ) WHEN 0 THEN 0 ELSE 0.3 END +
            CASE INSTR(LOWER(name_kakasi      ), :term_dk) WHEN 0 THEN 0 ELSE 0.3 END +
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
        ORDER BY weigth DESC, LOWER(name_romaji), id DESC
        LIMIT :limit
      SQL
      
      term_d = term.downcase
      term_q = "%#{term}%"
      query_params = { term_d: term_d, term_dk: term_d.to_romaji,
                       term_q: term_q, term_qk: term_q.to_romaji, limit: limit }
      
      self.find_by_sql [query, query_params]
    end # search_by_name
  end
end # SearchJapaneseSubject
