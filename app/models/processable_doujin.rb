class ProcessableDoujin < ApplicationRecord
  THUMB_FOLDER = 'samples'
  
  after_destroy :delete_files
  
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
  
  def file_path(full: false) = full ? File.join(Setting['dir.to_sort'], name) : name
  
  # append a hash to the url to ignore browser cache when the file name changes
  def name_hash = @cache_name_hash ||= Digest::MD5.hexdigest("djmngr|#{name}|#{name.size}")
  def thumb_url(mobile: false)  = "/#{THUMB_FOLDER}/#{'%010d' % id}-#{mobile ? :m : :d}.webp?h=#{name_hash}"
  
  def thumb_path(mobile: false) = Rails.root.join('public', THUMB_FOLDER, "#{'%010d' % id}-#{mobile ? :m : :d}.webp").to_s

  def delete_files
    File.unlink(thumb_path(mobile: true )) if File.exist?(thumb_path(mobile: true ))
    File.unlink(thumb_path(mobile: false)) if File.exist?(thumb_path(mobile: false))
  end # delete_files
  
  def process_later
    ProcessableDoujin.transaction do
      src_file = File.expand_path File.join(Setting['dir.to_sort'], name)
      dst_file = File.expand_path File.join(Setting['dir.to_sort'], DJ_DIR_PROCESS_LATER, name)
      
      update! name:        File.join(DJ_DIR_PROCESS_LATER, "#{name}"),
              name_kakasi: File.join(DJ_DIR_PROCESS_LATER, "#{name_kakasi}")
      
      # create dest folder and move file
      FileUtils.mkdir_p File.dirname(dst_file)
      FileUtils.mv src_file, dst_file, force: true
    end
  end # process_later
end
