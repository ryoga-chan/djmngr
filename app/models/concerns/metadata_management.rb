module MetadataManagement
  extend ActiveSupport::Concern

  # https://stackoverflow.com/questions/28300354/rails-problems-with-validation-in-concern/28300860#28300860
  include ActiveModel::Validations

  included do
    #belongs_to :alias_parent  , foreign_key: :doujinshi_org_aka_id, primary_key: :doujinshi_org_id, class_name: self.class.name
    #has_many   :alias_children, foreign_key: :doujinshi_org_aka_id, primary_key: :doujinshi_org_id, class_name: self.class.name
    def alias_parent   = self.class.find_by(doujinshi_org_id: doujinshi_org_aka_id.to_i)
    def alias_children = self.class.where(doujinshi_org_aka_id: doujinshi_org_id.to_i)

    has_paper_trail only: %i[ name name_romaji name_kana ], on: %i[ update ]

    validates :name, presence: true

    before_validation :sanitize_fields

    def sanitize_fields
      self.name_kakasi = name.to_romaji   if name_changed? || name_kakasi.blank?
      self.notes       = notes.to_s.strip if notes_changed?
    end # sanitize_fields

    # test if the link redirects to another item, and returns it
    def fetch_djorg_alias_url
      #begin
      #  req = HTTPX.with \
      #    timeout: { request_timeout: 5 },
      #    headers: { 'User-Agent' => ::Setting['scraper_useragent'] }
      #  resp = req.get doujinshi_org_full_url
      #
      #  return nil if resp.status != 302
      #
      #  # location header format: /browse/(author|circle|contents)/NUMERIC_ID/item_name/
      #  return nil if resp.headers[:location].to_s !~ /\/browse\/[^\/]+\/([0-9]+)\/.+/
      #
      #  resp.headers[:location]
      #rescue
      #  nil
      #end
      nil # WEBSITE NO MORE AVAILABLE
    end # fetch_djorg_alias_url
  end # included

  #class_methods do
  #end # class_methods
end # MetadataManagement
