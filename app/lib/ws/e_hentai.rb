# SEARCH: https://e-hentai.org/?f_search=terms
# API:    https://ehwiki.org/wiki/API
#
# SAMPLE API OUTPUT:
#   {"gmetadata":[
#     {
#   *   "gid":          0000000,
#   *   "token":        "0a0a0a0a0a",
#   *   "title":        "xxx",
#   *   "title_jpn":    "yyy",
#   *   "thumb":        "https:\/\/ehgt.org\/xx\/xx\/xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx-xxxxxxx-xxxx-xxxx-jpg_l.jpg",
#   *   "filecount":    "000",
#   *   "filesize":     0000,
#   *   "posted":       "0000",
#       "archiver_key": "xxxxxx--xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx",
#       "category":     "zzz",
#       "uploader":     "xxx",
#       "expunged":     false,
#       "rating":       "0.0",
#       "torrentcount": "0",
#       "torrents":     [],
#       "tags":         ["x","y",...]
#     }, { // when not-found returns:
#       "gid":          00000000,
#   *   "error":        "Key missing, or incorrect key provided."
#     }
#   ]}
module Ws::EHentai
  REQ = HTTPX.with \
    timeout: { request_timeout: 6 }
    #debug: STDERR, debug_level: 2
    
  REQ_HTML = REQ.with origin: 'https://e-hentai.org'
  REQ_API  = REQ.with origin: 'https://api.e-hentai.org'
  
  FIELDS = %i{ gid token title title_jpn thumb filecount filesize posted error }.freeze
  
  def self.search(term, options = {})
    headers = { 'User-Agent' => ::Setting['scraper_useragent'] }
    
    begin
      return result(:no_results) if term.blank?
      
      resp = REQ_HTML.
        with(headers: headers).
        get '/'.freeze, params: { f_search: term.to_s.strip }
      return result(:server_error) if resp.is_a?(HTTPX::ErrorResponse) || resp.status != 200
      
      # extract galleries ID & token
      results = resp.body.to_s.
        split('"').grep(/https:\/\/e-hentai.org\/g\/[0-9]+\/[^\/]+\//).
        map{|url| url.split('/')[-2..-1] }
      return result(:no_results) if results.empty?
      
      # query the API for results details
      resp = REQ_API.
        with(headers: headers.merge('Accept' => 'application/json')).
        post '/api.php'.freeze, json: { method: :gdata, gidlist: results, namespace: 1 }
      return result(:server_error) if resp.status != 200
      
      results = JSON.parse resp, symbolize_names: true rescue result(:parse)
      
      # extract and format results
      results[:gmetadata].map do |r|
        r.slice! *FIELDS
        
        if r[:error].nil?
          r[:posted] = Time.at r[:posted].to_i
          r[:url   ] = "https://e-hentai.org/g/#{r[:gid]}/#{r[:token]}/"
          r[:title_clean    ] = clean_title r[:title    ]
          r[:title_jpn_clean] = clean_title r[:title_jpn]
        end
        
        r
      end
    rescue HTTPX::TimeoutError
      return result(:server_error)
    end
  end # self.search
  
  
  private # ____________________________________________________________________
  
  
  def self.clean_title(text)
    if text.present?
      CGI.
        unescapeHTML(text).
        tokenize_doujin_filename(title_only: true, basename: false).
        join(' ')
    end
  end # self.clean_title
  
  def self.result(msg)
    msg = case msg
      when :server_error  then :'e-hentai server error'
      when :no_results    then :'no results found'
      when :parse         then :'response parsing error'
      else                     :'unknown error'
    end
    
    [{ gid: 0, error: msg }]
  end # self.result
end # module EHentai
