module MetadataManagement
  extend ActiveSupport::Concern
  
  # https://stackoverflow.com/questions/28300354/rails-problems-with-validation-in-concern/28300860#28300860
  include ActiveModel::Validations
  
  included do
    #belongs_to :alias_parent  , foreign_key: :doujinshi_org_aka_id, primary_key: :doujinshi_org_id, class_name: self.class.name
    #has_many   :alias_children, foreign_key: :doujinshi_org_aka_id, primary_key: :doujinshi_org_id, class_name: self.class.name
    def alias_parent   = self.class.find_by(doujinshi_org_id: doujinshi_org_aka_id)
    def alias_children = self.class.where(doujinshi_org_aka_id: doujinshi_org_id)
    
    has_paper_trail only: %i[ name name_romaji name_kana ], on: %i[ update ]
    
    validates :name, presence: true
    
    before_validation :sanitize_fields
    
    def sanitize_fields
      self.name_kakasi = name.to_romaji   if name_changed? || name_kakasi.blank?
      self.notes       = notes.to_s.strip if notes_changed?
    end # sanitize_fields
    
    # test if the link redirects to another item, and
    # eventually mark this as alias
    def djorg_url_aliased?
      return true if doujinshi_org_aka_id.present?
    
      req = ::HTTParty.get doujinshi_org_full_url, follow_redirects: false,
        headers: {'User-Agent' => Setting['scraper_useragent']}
      
      # /browse/(author|circle|contents)/NUMERIC_ID/item_name/
      if req.code == 302 && req.headers[:location].to_s =~ /\/browse\/[^\/]+\/([0-9]+)\/.+/
        begin
          transaction do
            # mark this item as duplicate/alias
            update doujinshi_org_aka_id: $1.to_i
            
            # download master item unless present on DB
            unless self.class.find_by(doujinshi_org_id: $1.to_i)
              self.class.djorg_sync "#{::DOUJINSHI_ORG_BASE_URL}#{req.headers[:location]}"
            end
          end # transaction
          
          return true
        rescue
        end
      end
      
      false
    end # djorg_url_aliased?
  end # included

  class_methods do
    # download and parse a page from doujinshi.org
    def djorg_sync(url)
      puts "##### URL: #{url}"
      true
    end # djorg_sync
  end # class_methods
end # MetadataManagement
