module CoreExt
  module String
    module Doujin
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
        ac1, ac2, fname = self.match(/^\[([^\]\(\)]+)(\(.+\))*\]\s*(.+)/).try(:captures)
        
        # extract authors/circles by splitting groups
        { ac_explicit:   ac1  .to_s.strip             .split(/\s*[,\|]\s*/),
          ac_implicit:   ac2  .to_s.strip[1...-1].to_s.split(/\s*[,\|]\s*/),
          subjects:      fname.present? ? self.sub(/^\[([^\]]+)\].+/, '\1') : '',
          properties:    self.match(/.+\([a-z,]+\)\....$/) ?
                           self.sub(/.+\(([a-z,]+)\)\....$/, '\1').split(',') : '',
          fname:         fname.to_s.strip }
      end # parse_doujin_filename
      
      def tokenize_doujin_filename(remove_numbers: false)
        cleared_string = File.basename self.strip, File.extname(self.strip)
        
        # keep author's parenthesis contents
        # drop all filename's parenthesis contents
        if cleared_string =~ /^\[([^\]]+)\](.+)$/
          cleared_string = "#{$1} #{$2.gsub /[\(\[\{][^\(\)]+[\)\]\}]/, ' '}"
        end
        
        cleared_string.gsub!(/[0-9]+/, ' ') if remove_numbers
        
        cleared_string.tr('[](){},.', ' ').split(' ')
      end # tokenize_doujin_filename
    end
  end
end

String.send :include, CoreExt::String::Doujin
