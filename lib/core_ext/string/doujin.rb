module CoreExt
  module String
    module Doujin
      # returns the explicit and implicit groups of authors_or_circles
      def parse_doujin_filename
        # GENERIC EXAMPLE:
        #   '[explicit_csv (implicit_csv)] filename.ext'
        # POSSIBLE CASES:
        #   '[author_circle name] file name.ext'
        #   '[author1 name, author2 name] file name.ext'
        #   '[author_circle name (author_or_alias1 name, author_or_alias2 name)] file name.ext'
        #   '[author1 name, author2 name (circle name)] file name.ext'
        #   '[author_circle1 name, author_circle2 name (author_or_alias1 name, author_or_alias2 name)] file name.ext'
        
        # extract groups
        ac1, ac2, fname = self.match(/^\[([^\]\(\)]+)(\(.+\))*\]\s*(.+)/).captures
        
        # extract authors/circles by splitting groups
        { ac1:   ac1  .to_s.strip             .split(/\s*[,\|]\s*/),
          ac2:   ac2  .to_s.strip[1...-1].to_s.split(/\s*[,\|]\s*/),
          fname: fname.to_s.strip }
      end # parse_doujin_filename
    end
  end
end

String.send :include, CoreExt::String::Doujin
