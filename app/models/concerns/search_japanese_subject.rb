module SearchJapaneseSubject
  extend ActiveSupport::Concern

  class_methods do
    def search(terms, search_method: 'linear')
      return self.none if terms.blank?
      
      tokens_orig    = terms.to_s          .tokenize_doujin_filename
      tokens_kakasi  = terms.to_s.to_romaji.tokenize_doujin_filename
      rel_conditions = []
      
      if search_method == 'sparse'
        # OPTION 1: search every term in any position
        %i[ name name_kana name_romaji name_kakasi ].each do |k|
          rel_conditions << tokens_orig  .inject(self){|rel, t| rel.where("#{k} LIKE ?", "%#{t}%") }
          rel_conditions << tokens_kakasi.inject(self){|rel, t| rel.where("#{k} LIKE ?", "%#{t}%") }
        end
      else # search_method == 'linear'
        # OPTION 2: search every term in sequence
        tokens_orig   = tokens_orig  .join '%'
        tokens_kakasi = tokens_kakasi.join '%'
        rel_conditions = [
          self.where("name        LIKE ?", "%#{tokens_orig  }%"),
          self.where("name        LIKE ?", "%#{tokens_kakasi}%"),
          self.where("name_kana   LIKE ?", "%#{tokens_orig  }%"),
          self.where("name_kana   LIKE ?", "%#{tokens_kakasi}%"),
          self.where("name_romaji LIKE ?", "%#{tokens_orig  }%"),
          self.where("name_romaji LIKE ?", "%#{tokens_kakasi}%"),
          self.where("name_kakasi LIKE ?", "%#{tokens_kakasi}%"),
        ]
      end
      
      # build query with all conditions in OR
      rel = rel_conditions.shift
      rel_conditions.each{|cond| rel = rel.or cond }
      
      rel.order(Arel.sql "COALESCE(NULLIF(name_romaji, ''), NULLIF(name_kakasi, ''))")
    end # self.search
    
    # search elements by a single term and rank them by score
    def search_by_name(term, limit: 10)
      return self.where("1 <> 1") if term.to_s.blank?
      
      klass = self.name.downcase
      
      # NOTE: sqlite LIKE is case insensitive! => we can skip LOWER() to speed up WHERE
      # https://www.sqlite.org/optoverview.html#the_like_optimization
      query = <<~SQL
        SELECT
            t.*
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
          , (SELECT COUNT(1) FROM #{klass.pluralize}_doujinshi WHERE #{klass}_id = t.id) AS num_dj
        FROM #{self.table_name} t
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
      query_params = { term_d: term_d, term_dk: term_d.to_romaji,
                       term_q: "%#{term}%", term_qk: "%#{term.to_romaji}%", limit: limit }
      
      self.find_by_sql [query, query_params]
    end # search_by_name
  end
end # SearchJapaneseSubject
