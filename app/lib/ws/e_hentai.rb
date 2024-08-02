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
  # https://honeyryderchuck.gitlab.io/httpx/wiki/Cookies
  REQ = HTTPX.plugin(:cookies).plugin(:follow_redirects).with \
    timeout: { request_timeout: 6 }
    #debug: STDERR, debug_level: 2
  REQ_EH  = REQ.with origin: 'https://e-hentai.org'
  REQ_EX  = REQ.with origin: 'https://exhentai.org'
  REQ_API = REQ.with origin: 'https://api.e-hentai.org'

  FIELDS = %i[ gid token title title_jpn thumb filecount filesize posted error ].freeze

  def self.do_login
    return nil if Setting[:ehentai_auth].blank?

    user, pass = Setting[:ehentai_auth].split(':', 2)

    r = REQ.with(headers: { 'User-Agent' => ::Setting['scraper_useragent'] })
    p = r.post 'https://forums.e-hentai.org/index.php?act=Login&CODE=01',
      form: { UserName: user, PassWord: pass,
              CookieDate: 1, b: :d, bt: '1-1', ipb_login_submit: 'Login!' }
    return nil unless p.to_s.include?('You are now logged in')

    p = r.get 'https://e-hentai.org/bounce_login.php?b=d&bt=1-1'
    return nil unless p.to_s.include?('Moderation Power')

    r
  end # self.do_login

  def self.cookies_path = File.join(Setting[:'dir.sorting'], 'eh-cookies.yml')

  def self.dump_cookies(req, fpath)
    return unless req

    File.open(fpath, 'w') do |f|
      f.puts req.cookies.map{|c| {
        name: c.name, value: c.value,
        path: c.path, domain: c.domain,
        expires: c.expires, max_age: c.try(:max_age)
      }.compact }.to_yaml
    end
  end # self.dump_cookies

  def self.load_cookies(req, fpath) = req.with_cookies(YAML.unsafe_load_file fpath)
  
  def self.clear_cookies = FileUtils.rm_f(cookies_path)

  def self.search(term, options = {})
    headers = { 'User-Agent' => ::Setting['scraper_useragent'] }
    cookies_file = cookies_path

    begin
      term = term.split(' ').reject{|i| i.size == 1}.join(' ').gsub(/([^0-9])0+([0-9]+)/, '\1\2')
      
      return result(:no_results) if term.blank?

      unless File.exist?(cookies_file)
        req = do_login
        dump_cookies req, cookies_file
      end

      site = :'e-hentai'
      resp = nil

      if File.exist?(cookies_file)
        req  = load_cookies(REQ_EX, cookies_file).with(headers: headers)
        resp = req.get '/'.freeze, params: { f_search: term.to_s.strip }
        return result(:server_error) if resp.is_a?(HTTPX::ErrorResponse) || resp.status != 200

        if resp.to_s.include?('ExHentai.org') && resp.to_s.include?('Search Keywords')
          site = :'exhentai'
          dump_cookies req, cookies_file
        else
          File.unlink cookies_file
        end
      end

      unless File.exist?(cookies_file)
        resp = REQ_EH.
          with(headers: headers).
          get '/'.freeze, params: { f_search: term.to_s.strip }
        return result(:server_error) if resp.is_a?(HTTPX::ErrorResponse) || resp.status != 200
      end

      # extract galleries ID & token
      results = resp.body.to_s.
        split('"').grep(/https:\/\/#{site}.org\/g\/[0-9]+\/[^\/]+\//).
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
          r[:site  ] = site
          r[:posted] = Time.at r[:posted].to_i
          r[:url   ] = "https://#{site}.org/g/#{r[:gid]}/#{r[:token]}/"
          if r[:title].include?(' | ')
            r[:title], r[:title_eng] = r[:title].split(' | ', 2)
            r[:title_eng_clean] = clean_title r[:title_eng]
          end
          r[:title_clean    ] = clean_title r[:title    ]
          r[:title_jpn_clean] = clean_title r[:title_jpn]
        end

        r
      end
    rescue HTTPX::TimeoutError
      result :server_error
    end
  end # self.search


  private # ____________________________________________________________________


  def self.clean_title(text)
    if text.present?
      CGI.
        unescapeHTML(text).
        tokenize_doujin_filename(title_only: true, basename: false, rm_sym: false).
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
