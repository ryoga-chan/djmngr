class DeletedDoujin < ApplicationRecord
  # attribute used to store cover matching similarity based on hamming distance of pHashes
  attr_internal_accessor :cover_similarity

  def self.search(terms)
    fname_info    = terms.to_s.strip    .parse_doujin_filename
    tokens_orig   = terms.to_s          .tokenize_doujin_filename.join '%'
    tokens_kakasi = terms.to_s.to_romaji.tokenize_doujin_filename.join '%'

    return self.none if tokens_orig.size < 3

    # search all terms on the original filename
    rel_conditions = [
      DeletedDoujin.where("name            LIKE ?", "%#{tokens_orig  }%"),
      DeletedDoujin.where("name_kakasi     LIKE ?", "%#{tokens_kakasi}%"),
      DeletedDoujin.where("alt_name        LIKE ?", "%#{tokens_orig  }%"),
      DeletedDoujin.where("alt_name_kakasi LIKE ?", "%#{tokens_kakasi}%"),
    ]

    # search only filename terms
    if fname_info[:fname].present?
      tokens_orig   = fname_info[:fname].to_s          .tokenize_doujin_filename.join '%'
      tokens_kakasi = fname_info[:fname].to_s.to_romaji.tokenize_doujin_filename.join '%'
      rel_conditions += [
        DeletedDoujin.where("name            LIKE ?", "%#{tokens_orig  }%"),
        DeletedDoujin.where("name_kakasi     LIKE ?", "%#{tokens_kakasi}%"),
        DeletedDoujin.where("alt_name        LIKE ?", "%#{tokens_orig  }%"),
        DeletedDoujin.where("alt_name_kakasi LIKE ?", "%#{tokens_kakasi}%"),
      ]
    end

    # build query with all conditions in OR
    rel = rel_conditions.shift
    rel_conditions.each{|cond| rel = rel.or cond }

    rel.order(Arel.sql "COALESCE(NULLIF(alt_name_kakasi, ''), NULLIF(name_kakasi, ''))")
  end # self.search

  def cover_fingerprint!(h)
    raise :record_not_persisted unless persisted?
    update! cover_phash: h[:phash], cover_idhash: h[:idhash]
  end # cover_fingerprint!
end
