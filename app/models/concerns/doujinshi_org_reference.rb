module DoujinshiOrgReference
  extend ActiveSupport::Concern
  
  DOUJINSHI_ORG_BASE_URL = 'https://www.doujinshi.org'.freeze

  included do
    def doujinshi_org_full_url = "#{DOUJINSHI_ORG_BASE_URL}#{doujinshi_org_url}"
  end

  class_methods do
    def doujinshi_org_search_url(term)
      link_params = {sn: term}.to_query
      "#{DOUJINSHI_ORG_BASE_URL}/search/simple/?T=#{self.name.downcase}&#{link_params}"
    end # doujinshi_org_search_url
  end
end # DoujinshiOrgReference
