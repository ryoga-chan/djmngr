# rm -rf djmngr ; rails new djmngr --rc=railsrc

# https://edgeguides.rubyonrails.org/rails_application_templates.html
#   https://api.rubyonrails.org/classes/Rails/Generators/Actions.html
#   https://www.rubydoc.info/github/wycats/thor/master/Thor/Actions
# https://dev.to/eclecticcoding/rails-basic-template-3opg
#   https://github.com/eclectic-coding/rails_default_template/blob/main/template.rb

require 'fileutils'

FileUtils.mkdir 'docs', mode: 0755
FileUtils.cp %w{ ../railsrc ../template.rb ../create-app.sh }, './docs/'

# --- setup gems ----------------------------------------------------------
# https://guides.rubyonrails.org/asset_pipeline.html
#   https://stackoverflow.com/questions/55213868/rails-6-how-to-disable-webpack-and-use-sprockets-instead/58518795#58518795
#   https://github.com/ecovillage/cabler/commit/c0329c77613faaf747004986e2df1eb5b5cb35b8
append_to_file 'Gemfile', "\n# -------------------------------------------------------------------------\n\n"
gsub_file 'Gemfile', /"/, "'"
gsub_file 'Gemfile', /^# (gem .sassc-rails)/, '\1'        # enable sassc
gsub_file 'Gemfile', /^# (gem .bcrypt)/, '\1'             # enable bcrypt
gsub_file 'Gemfile', /^# (gem .image_processing)/, '\1'   # enable image_processing -- dpkg install libvips42
gsub_file 'Gemfile', /^(.+)(gem .web-console)/, '\1# \2'  # disable web-console
gsub_file 'Gemfile', /^(gem .importmap-rails)/, '# \1'  # disable importmap
gsub_file 'Gemfile', /^.+kredis.+\n/i, ''                 # strip kredis comments
gem 'haml-rails', '~> 2.0'  # https://haml.info
gem 'kaminari'  # pagination -- https://github.com/kaminari/kaminari
gem 'kakasi'    # kanji kana simple inverter -- https://github.com/knu/kakasi_ffi
gem 'ferret', '0.11.9.0', source: 'https://rubygems.pkg.github.com/acavalin' # https://github.com/acavalin/ferret#instructions

# --- setup sprockets -----------------------------------------------------
# https://github.com/rails/sprockets#directives
append_to_file  'app/assets/config/manifest.js', "//= link_directory ../javascripts .js\n"

create_file     'app/assets/javascripts/application.js' , ''
append_to_file  'app/assets/javascripts/application.js' , "//= require jquery\n"
# https://github.com/rails/rails-ujs ==> MOVED TO: 
# https://github.com/rails/rails/tree/main/actionview/app/assets/javascripts
append_to_file  'app/assets/javascripts/application.js' , "//= require rails-ujs\n"
append_to_file  'app/assets/javascripts/application.js' , "//= require_tree .\n"

gsub_file       'app/assets/stylesheets/application.css', /.+= require_.+$/, ''
append_to_file  'app/assets/stylesheets/application.css', "//= require ./bulma/theme_darkly\n"
 
# use javascript_include_tag
gsub_file 'app/views/layouts/application.html.erb', '  </head>', %Q|    <%= javascript_include_tag "application" %>\n  </head>|

# compress JS files in production
environment 'config.assets.js_compressor  = :uglify', env: 'production'
environment 'config.assets.css_compressor = :scss'  , env: 'production'

# fix "Asset compilation stalls with sprockets v4" @ https://github.com/rails/sprockets/issues/640#issuecomment-546948748
append_to_file 'config/initializers/assets.rb', "Sprockets.export_concurrent = false\n"

# --- config app ----------------------------------------------------------
# https://wiki.mozilla.org/Security/Server_Side_TLS
# https://cipherlist.eu/
environment "config.force_ssl = ENV['NOSSL'].blank? ? true : false", env: 'production'

after_bundle do
  # convert layout from ERB to HAML
  rails_command 'generate haml:application_layout convert'
  remove_file   'app/views/layouts/application.html.erb'
  
  # default landing page
  rails_command 'generate controller home index'
  route "root 'home#index'"

  append_to_file '.gitignore', "\nGemfile.lock\n"
  
  create_file 'app/models/current.rb', <<~'RUBY'
    # https://api.rubyonrails.org/classes/ActiveSupport/CurrentAttributes.html
    # https://stackoverflow.com/questions/2513383/access-current-user-in-model#2513456
    class Current < ActiveSupport::CurrentAttributes
      attribute :user
    end
  RUBY

  git add: '.' ; git commit: "-a -m 'Initial commit'"
  
  # jQuery: update script & download
  create_file 'bin/update-jquery', <<~'SHELL'
    #!/bin/sh
    VER=`curl -sL https://github.com/jquery/jquery/releases | grep '/tree/' | head -n 1 | sed -r 's:.+/([0-9.]+).+:\1:'`
    URL="https://code.jquery.com/jquery-$VER.js" # or $VER.min
    echo "DL $VER @ $URL"
    curl -Lo app/assets/javascripts/jquery.js $URL
  SHELL
  run %Q| chmod 755 bin/update-jquery |
  run %Q| bin/update-jquery |
  git add: '.' ; git commit: "-a -m 'add jQuery'"

  # Bulma: update script & download
  # from https://github.com/bananaappletw/bulma-sass/blob/master/release.sh
  create_file 'bin/update-bulma', <<~'SHELL'
    #!/bin/sh
    VER=`curl -sL https://github.com/jgthms/bulma/releases | grep '/tree/' | head -n 1 | sed -r 's:.+/([0-9.]+).+:\1:'`
    URL="https://github.com/jgthms/bulma/releases/download/$VER/bulma-$VER.zip"
    echo "DL $VER @ $URL"
    curl -Lo tmp/bulma.zip $URL
    unzip -oqd app/assets/stylesheets tmp/bulma.zip bulma/bulma.sass 'bulma/sass/*' -x '*.DS_Store' \
      && rm -f tmp/bulma.zip
  SHELL
  run %Q| chmod 755 bin/update-bulma |
  run %Q| bin/update-bulma |
  
  create_file 'config/initializers/field_error_proc.rb', <<~'RUBY'
    # https://stackoverflow.com/questions/12252286/how-to-change-the-default-rails-error-div-field-with-errors
    ActionView::Base.field_error_proc = Proc.new do |html_tag, instance|
      # add class is-danger
      if html_tag.include?('class="')
        html_tag.sub(/(class="[^"]+)"/, '\1 is-danger"').html_safe
      else
        i = html_tag.index(' ')
        %Q|#{html_tag[0..(i-1)]} class="is-danger"#{html_tag[i..-1]}|.html_safe
      end
    end
  RUBY
  
  # https://jenil.github.io/bulmaswatch/darkly/
  run %Q[ curl -sL https://github.com/jenil/bulmaswatch/raw/gh-pages/darkly/_variables.scss > app/assets/stylesheets/bulma/theme_darkly-variables.scss ]
  run %Q[ curl -sL https://github.com/jenil/bulmaswatch/raw/gh-pages/darkly/_overrides.scss > app/assets/stylesheets/bulma/theme_darkly-overrides.scss ]
  create_file 'app/assets/stylesheets/bulma/theme_darkly.scss', <<~'SCSS'
    @charset "utf-8"
    /*! bulmaswatch v0.8.1 | MIT License */
    @import "theme_darkly-variables";
    @import "bulma";
    @import "theme_darkly-overrides";
  SCSS
  
  git add: '.' ; git commit: "-a -m 'add Bulma CSS'"
end
