module CoreExt::String::Doujin
  IGNORED_TAGS = [
    / *[\(（]#nijisousaku [0-9]+[）\)] */,
    / *[\(（]#にじそうさく[0-9]+[）\)] */,
    / *[\(（][0-9]+年[0-9]+月秋葉原超同人祭[）\)] */,
    / *[\(（]ac[0-9]+[）\)] */,
    / *[\(（]akihabara chou doujinsai[）\)] */,
    / *[\(（]akihabaradoujinsai [0-9]+[）\)] */,
    / *[\(（]c[0-9]{2,3}[）\)] */,
    / *[\(（]comic1 bs-sai special[）\)] */,
    / *[\(（]comic1 bs祭 スペシャル[）\)] */,
    / *[\(（]comic[0-9]+[^0-9][0-9]+[）\)] */,
    / *[\(（]comic[0-9]☆[0-9]{1,2}[）\)] */,
    / *[\(（]comitia[0-9]+[）\)] */,
    / *[\(（]csp[0-9]+[）\)] */,
    / *[\(（]ct[0-9]{2}[）\)] */,
    / *[\(（]ff[0-9]{2}[）\)] */,
    / *[\(（]futaket *[0-9]+[）\)] */,
    / *[\(（]futaket [0-9\.]+[）\)] */,
    / *[\(（]gw超同人祭[）\)] */,
    / *[\(（]houraigekisen! yo-i! [0-9]+senme[）\)] */,
    / *[\(（]hyousou strast [0-9]+[）\)] */,
    / *[\(（]idol star festiv@l [0-9]+[）\)] */,
    / *[\(（]kouroumu [0-9]+[）\)] */,
    / *[\(（]messa kininaruu [0-9]+[）\)] */,
    / *[\(（]reitaisai *[0-9]+[）\)] */,
    / *[\(（]sc20.. [a-z]+[）\)] */,
    / *[\(（]sc[0-9]{2}[）\)] */,
    / *[\(（]shuuki reitaisai [0-9]+[）\)] */,
    / *[\(（]あなたとラブライブ! [0-9]+[）\)] */,
    / *[\(（]こみトレ[0-9]+[）\)] */,
    / *[\(（]ぱんっあ☆ふぉー![0-9]+[）\)] */,
    / *[\(（]ふたけっと[0-9]+(\.[0-9])*[）\)] */,
    / *[\(（]ぷにケット[0-9]+[）\)] */,
    / *[\(（]エアコミケ[0-9]+[）\)] */,
    / *[\(（]カラフルマスターレボリューション[）\)] */,
    / *[\(（]ゲームcg[）\)] */,
    / *[\(（]コミティア[0-9]+[）\)] */,
    / *[\(（]サンクリ20.. [a-z]+[）\)] */,
    / *[\(（]サンクリ[0-9]+[）\)] */,
    / *[\(（]スタンドアップ![0-9]+[）\)] */,
    / *[\(（]プリズム☆ジャンプ[0-9]+[）\)] */,
    / *[\(（]ボイスコネクト[）\)] */,
    / *[\(（]メガ秋葉原同人祭[0-9]+[）\)] */,
    / *[\(（]レインボーフレーバー[0-9]+[）\)] */,
    / *[\(（]例大祭[0-9]+[）\)] */,
    / *[\(（]同人cg集[）\)] */,
    / *[\(（]同人誌[）\)] */,
    / *[\(（]成年コミック[）\)] */,
    / *[\(（]歌姫庭園[0-9]+[）\)] */,
    / *[\(（]秋季例大祭[0-9]+[）\)] */,
    / *[\(（]秋葉原超同人祭[）\)] */,
    / *[\(（]第[0-9]+回ウルトラサマーフェスタ[）\)] */,
    / *[\(（]紅楼夢[0-9]+[）\)] */,
    / *[\(（]僕らのラブライブ! [0-9]+[）\)] */,
    / *[\(（]僕ラブ!サンシャインin沼津[0-9]+[）\)] */,
    / *\[雑誌\] */,
  ]

  TOKENIZE_RE_NAME = /^(\[[^\[\]]+\])*\s*(\([^\[\]]+\))*\s*\[([^\]\(\)]+)(\([^\[\]]+\))*\]\s*([^\[\]\(\)]+)(\([^\[\]]+\))*\s*(\[[^\[\]]+\])*\s*/

  TOKENIZE_RE_SYMBOLS  = /[!@\[;\]^%*\(\);\-_+=\?\.,'\/&\\|$\{#\}<>:`~"]/

  # returns the explicit and implicit groups of authors_or_circles
  def parse_doujin_filename
    # GENERIC EXAMPLE:
    #   '[explicit_csv (implicit_csv)] filename (tags).ext'
    # POSSIBLE CASES:
    #   '[author_circle name] file name (eng,unc,col).ext'
    #   '[author1 name, author2 name] file name.ext'
    #   '[author_circle name (author_or_alias1 name, author_or_alias2 name)] file name.ext'
    #   '[author1 name, author2 name (circle name)] file name.ext'
    #   '[author_circle1 name, author_circle2 name (author_or_alias1 name, author_or_alias2 name)] file name.ext'

    # extract groups
    ac1, ac2, fname = self.match(/^\[([^\]\(\)]+)(\([^\[\]]+\))*\]\s*(.+)/).try(:captures)

    # extract authors/circles by splitting groups
    result = {
      ac_explicit:   ac1  .to_s.strip             .split(/\s*[,\|]\s*/),
      ac_implicit:   ac2  .to_s.strip[1...-1].to_s.split(/\s*[,\|]\s*/),
      subjects:      fname.present? ? self.sub(/^\[([^\]]+)\].+/, '\1') : '', # everything between []
      properties:    self.match(/.+\([a-z,]+\)\....$/) ?  # eg. (eng,col,unc)
                       self.sub(/.+\(([a-z,]+)\)\....$/, '\1').split(',') : '',
      fname:         fname.to_s.strip
    }
    
    self_downcase = self.downcase
    
    # detect censorship
    unless result[:properties].include?('unc')
      # decensored uncensored, 無修正 (jap), 未经审查 (chi), 무수정 (kor)
      result[:properties] << 'unc' if %w(decens uncens 無修正 未经审查 무수정).any?{|i| self_downcase.include?(i) }
    end
    
    # detect language
    result[:language] = Doujin::LANGUAGES.
      detect{|descr, lbl| result[:properties].include?(lbl) || self_downcase.include?(descr.downcase) }.try('[]', 1)
    result[:language] ||= 'jpn' if self_downcase.include?('日本語')
    result[:language] ||= 'eng' if self_downcase.include?('英語')
    result[:language] ||= 'kor' if self_downcase.include?('韓国語')
    result[:language] ||= 'chi' if self_downcase.include?('中国') # 中国語, 中国翻訳
    result[:language] ||= Doujin::LANGUAGES.values.first
    
    result
  end # parse_doujin_filename

  def first_author_from_filename
    info = self.parse_doujin_filename
    "#{info[:ac_explicit].join ' '} #{info[:ac_implicit].join ' '}".strip
  end # first_author_from_filename

  def tokenize_doujin_filename(rm_num: false, title_only: false, basename: true)
    term = dup

    term = File.basename term if basename

    # remove common archive file extension
    ext = File.extname term
    term = File.basename term, ext if ext =~ /\A.(zip|cbz|rar|cbr|7z|cb7|tar|t.z)\z/i

    # remove unwanted tags
    term = IGNORED_TAGS.inject(term.downcase){|t, re| t.gsub re, '' }.strip

    # remove numbers
    term.gsub!(/[0-9]+/, ' ') if rm_num

    # [tags] (tags) [csv_circles (csv_authors)] title (tags) [tags]
    if md = term.match(TOKENIZE_RE_NAME)
      s_tag1, r_tag1, author1, author2, title, r_tag2, s_tag2 = md.captures
      #puts({s_tag1: s_tag1, r_tag1: r_tag1, author1: author1, author2: author2, title: title, r_tag2: r_tag2, s_tag2: s_tag2}.inspect)
      author2.delete! '()' if author2
      term = title_only ? title : [author1, author2, title].compact.join(' ')
    end

    # drop symbols and multiple spaces
    term.gsub(TOKENIZE_RE_SYMBOLS, ' ').split(' ')
  end # tokenize_doujin_filename
end

String.send :include, CoreExt::String::Doujin
