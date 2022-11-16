class Doujin < ApplicationRecord
  LANGUAGES = { # https://www.abbreviations.com
    'Japanese'   => 'jpn',
    'English'    => 'eng',
    'Chinese'    => 'chi',
    'Italian'    => 'ita',
    'French'     => 'fra',
    'Spanish'    => 'spa',
    'Deutsch'    => 'deu',
    'None/Other' => '???',
  }.freeze

  has_and_belongs_to_many :authors, before_add: -> (d, a) {
    return unless d.authors.where(id: a.id).exists? # ensure uniqueness
    d.errors.add :base, "author already associated [#{a.id}: #{a.name}]"
    throw :abort
  }
  has_and_belongs_to_many :circles, before_add: -> (d, c) {
    return unless d.circles.where(id: c.id).exists? # ensure uniqueness
    d.errors.add :base, "circle already associated [#{c.id}: #{c.name}]"
    throw :abort
  }
  
  has_paper_trail only: %i[ name name_romaji name_orig ], on: %i[ update ]
  
  validates :name, :size, :checksum, :num_images, :num_files,
            :category, :file_folder, :file_name,
            presence: true
  validate  :validates_rename_file, on: :update
  
  before_validation :sanitize_fields
  before_destroy    :delete_versions
  after_update      :rename_file
  after_destroy     :delete_files
  after_destroy     :save_deletion_data
  
  include JapaneseLabels
  include FavoriteManagement
  
  # attribute used to store cover matching similarity based on hamming distance of pHashes
  attr_internal_accessor :cover_similarity
  
  def sanitize_fields
    self.scored_at = Time.now if score_changed?
    
    self.name_kakasi      = name     .to_romaji if name_changed? || name_kakasi.blank?
    self.name_orig_kakasi = name_orig.to_romaji if name_orig_changed?
    self.notes            = notes.to_s.strip    if notes_changed?
  end # sanitize_fields
  
  def validates_rename_file
    if file_name_changed?
      errors.add :file_name, "file name not ending in \".zip\"" unless file_name.ends_with?('.zip')
      errors.add :file_name, "file name already exist"          if File.exist?(file_path full: true)
      @old_file_path = file_path(full: true, alter_file_name: file_name_was) if errors[:file_name].empty?
    end
  end # validates_rename_file
  
  def self.dest_path_by_process_params(info, full_path: false)
    path = full_path ? [Setting['dir.sorted']] : []
    path << (info[:file_type] == 'doujin' ? info[:doujin_dest_type] : info[:file_type]).to_s
    path << info[:dest_folder  ].to_s.gsub(/[\/\\]/, '_')
    path << info[:subfolder    ].to_s.gsub(/[\/\\]/, '_')
    path << info[:dest_filename].to_s.gsub(/[\/\\]/, '_')
    File.join '/', *path
  end # self.dest_path_by_process_params
  
  # find doujin by destination folder
  def self.find_by_process_params(info)
    cat  = (info[:file_type] == 'doujin' ? info[:doujin_dest_type] : info[:file_type]).to_s
    fold = File.join *[info[:dest_folder], info[:subfolder]].select(&:present?).map{|i| i.to_s.gsub(/[\/\\]/, '_') }
    fold = '.' if fold.blank?
    name = info[:dest_filename].to_s.gsub(/[\/\\]/, '_')
    find_by category: cat, file_folder: fold, file_name: name
  end # self.find_by_process_params
  
  def file_path(full: false, alter_file_name: nil)
    tmp_folder = file_folder == '.' ? '' : file_folder
    tmp_path = File.join category, tmp_folder, (alter_file_name || file_name)
    full ? File.join(Setting['dir.sorted'], tmp_path) : tmp_path
  end # file_path
  
  def file_contents
    File.read file_path(full: true)
  end # file_contents
  
  # infer a default artist and filename
  def file_dl_info
    return @file_dl_info if @file_dl_info
  
    @file_dl_info = {}
    
    tmp_folder = file_folder == '.' ? '' : file_folder
    
    case self.category
      when 'author', 'circle'
        tmp_author, tmp_subfolder = tmp_folder.split(File::SEPARATOR, 2)
        @file_dl_info[:author  ] = tmp_author
        @file_dl_info[:filename] = file_name
        @file_dl_info[:filename] = "#{tmp_subfolder} -- #{@file_dl_info[:filename]}" if tmp_subfolder
      when 'artbook', 'magazine'
        tmp_folder, tmp_subfolder = tmp_folder.split(File::SEPARATOR, 2)
        @file_dl_info[:author  ] = 'various'
        @file_dl_info[:filename] = "{#{category[0..2]}} "
        @file_dl_info[:filename] += "#{tmp_folder} #{'-- ' if category == 'artbook'}" if tmp_folder.present?
        @file_dl_info[:filename] += "- #{tmp_subfolder} " if tmp_subfolder.present?
        @file_dl_info[:filename] += file_name
    end
    
    @file_dl_info[:ext] = File.extname @file_dl_info[:filename]
    @file_dl_info[:filename] = File.basename @file_dl_info[:filename], @file_dl_info[:ext]
    
    @file_dl_info
  end # file_dl_info
  
  def file_dl_name(omit_ext: false)
    return @file_dl_name if @file_dl_name
    
    info = file_dl_info
    
    @file_dl_name = case category
      when 'author', 'circle'   ; "[#{info[:author]}] #{info[:filename]}#{info[:ext] unless omit_ext}"
      when 'artbook', 'magazine'; "#{info[:filename]}#{info[:ext] unless omit_ext}"
    end
  end # file_dl_name
  
  def thumb_disk_path = Rails.root.join('public', 'thumbs', "#{id}.webp").to_s
  
  def destroy_with_files
    @delete_files = true
    destroy
  end # destroy_with_files
  
  def percent_read = (read_pages.to_f / num_images * 100).round(2)
  
  def check_hash? = checksum == `sha512sum -b #{file_path(full: true).shellescape}`.split(' ', 2)[0]
  
  def check_zip?
    `unzip -qt #{file_path(full: true).shellescape}`
    $?.to_i == 0
  end # check_zip?
  
  def refresh_checksum!
    tmp_hash = `sha512sum -b #{file_path(full: true).shellescape}`.split(' ', 2)[0].to_s.strip
    tmp_hash.size == 128 ? update(checksum: tmp_hash) : false
  end # refresh_checksum!
  
  def self.search(terms)
    fname_info    = terms.to_s.strip    .parse_doujin_filename
    tokens_orig   = terms.to_s          .tokenize_doujin_filename.join '%'
    tokens_kakasi = terms.to_s.to_romaji.tokenize_doujin_filename.join '%'
    
    return self.none if tokens_orig.size < 3
    
    # search all terms on the original filename
    rel_conditions = [
      Doujin.where("name_orig        LIKE ?", "%#{tokens_orig  }%"),
      Doujin.where("name_orig_kakasi LIKE ?", "%#{tokens_kakasi}%"),
      Doujin.where("name_orig        LIKE ?", "%#{tokens_orig  }%"),
      Doujin.where("name_orig_kakasi LIKE ?", "%#{tokens_kakasi}%"),
    ]
    
    # search only filename terms on user filled fields
    title_terms   = fname_info[:fname].present? ? fname_info[:fname] : terms
    tokens_orig   = title_terms.to_s          .tokenize_doujin_filename.join '%'
    tokens_kakasi = title_terms.to_s.to_romaji.tokenize_doujin_filename.join '%'
    rel_conditions += [
      Doujin.where("name        LIKE ?", "%#{tokens_orig  }%"),
      Doujin.where("name        LIKE ?", "%#{tokens_kakasi}%"),
      Doujin.where("name_romaji LIKE ?", "%#{tokens_orig  }%"),
      Doujin.where("name_romaji LIKE ?", "%#{tokens_kakasi}%"),
      Doujin.where("name_kakasi LIKE ?", "%#{tokens_kakasi}%"),
    ]
    
    # build query with all conditions in OR
    rel = rel_conditions.shift
    rel_conditions.each{|cond| rel = rel.or cond }
    
    rel.order(Arel.sql "COALESCE(NULLIF(name_romaji, ''), NULLIF(name_kakasi, ''))")
  end # self.search
  
  def cover_fingerprint = '%016x' % Phashion::Image.new(thumb_disk_path).fingerprint
  
  def cover_fingerprint!
    f = cover_fingerprint
    self.class.connection.execute %Q|UPDATE doujinshi SET cover_phash = 0x#{f} WHERE id = #{id}|
    f
  end # cover_fingerprint!
  
  # next page numer for `/doujinshi/ID/read` action
  def next_page_to_read
    return 0 unless (0...(num_images-1)).include?(read_pages.to_i - 1)
    read_pages.to_i - 1
  end # next_page_to_read
  
  
  private # ____________________________________________________________________
  
  
  def delete_files
    return unless @delete_files
    [
      file_path(full: true), # doujin file
      File.join(Rails.root, 'public', 'thumbs', "#{id}.webp"), # thumbnail
    ].each{|f| File.unlink(f) if File.exist?(f) }
  end # delete_files
  
  def delete_versions = versions.destroy_all
  
  def rename_file
    FileUtils.mv @old_file_path, file_path(full: true), force: true if @old_file_path
  end # rename_file
  
  def save_deletion_data
    attrs = attributes.slice *%w{ size num_images num_files }
    fname = file_dl_name omit_ext: true
    
    DeletedDoujin.create attrs.merge({
      doujin_id:        id,
      name:             name_orig,
      name_kakasi:      name_orig_kakasi,
      alt_name:         fname,
      alt_name_kakasi:  fname.to_romaji,
    })
  end # save_deletion_data
end
