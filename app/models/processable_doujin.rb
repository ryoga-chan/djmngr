class ProcessableDoujin < ApplicationRecord
  def self.search(terms)
    fname_info    = terms.to_s.strip    .parse_doujin_filename
    tokens_orig   = terms.to_s          .tokenize_doujin_filename.join '%'
    tokens_kakasi = terms.to_s.to_romaji.tokenize_doujin_filename.join '%'
    
    return self.none if tokens_orig.size < 3
    
    # search all terms on the original filename
    rel_conditions = [
      ProcessableDoujin.where("name            LIKE ?", "%#{tokens_orig  }%"),
      ProcessableDoujin.where("name_kakasi     LIKE ?", "%#{tokens_kakasi}%"),
    ]
    
    # search only filename terms
    if fname_info[:fname].present?
      tokens_orig   = fname_info[:fname].to_s          .tokenize_doujin_filename.join '%'
      tokens_kakasi = fname_info[:fname].to_s.to_romaji.tokenize_doujin_filename.join '%'
      rel_conditions += [
        ProcessableDoujin.where("name            LIKE ?", "%#{tokens_orig  }%"),
        ProcessableDoujin.where("name_kakasi     LIKE ?", "%#{tokens_kakasi}%"),
      ]
    end
    
    # build query with all conditions in OR
    rel = rel_conditions.shift
    rel_conditions.each{|cond| rel = rel.or cond }
    
    rel.order(:name_kakasi)
  end # self.search
end
