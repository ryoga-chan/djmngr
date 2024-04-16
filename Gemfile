source 'https://rubygems.org'

# HOWTO: update gems and remove old versions
#   bundle update
#   gem cleanup

ruby '3.3.0'

gem 'rails',       '~> 7.1.2',     # to use edge: gem 'rails', github: 'rails/rails', branch: 'main'
  require: %w[ shellwords open-uri pp open3 ]
gem 'sqlite3',     '~> 1.4'      # sqlite3 database for Active Record
gem 'puma',        '~> 6.0'      # puma web server -- https://github.com/puma/puma
#gem 'rack-brotli', '~> 1.2'      # enable brotli compression !!SEGFAULT using send_file!!
gem 'sassc-rails'                # sass to process CSS
gem 'sprockets-rails'            # asset pipeline -- https://github.com/rails/sprockets-rails
gem 'tzinfo-data', platforms: %i[ windows jruby ] # zoneinfo files for Windows
gem 'haml-rails',  '~> 2.0'      # https://haml.info
gem 'kaminari'                   # pagination -- https://github.com/kaminari/kaminari
gem 'kakasi'                     # kanji kana simple inverter -- https://github.com/knu/kakasi_ffi
gem 'lograge'                    # greppable logs -- https://github.com/roidrage/lograge
gem 'marcel'                     # mime type of files -- https://github.com/rails/marcel
gem 'progressbar'                # cli progressbar -- https://github.com/jfelchner/ruby-progressbar
gem 'rubyzip', '~> 2.3', require: 'zip' # manage ZIP files -- https://github.com/rubyzip/rubyzip
gem 'paper_trail', '~> 15.0'     # track model changes -- https://github.com/paper-trail-gem/paper_trail
gem 'colorize', require: 'colorized_string' # terminal colors -- https://github.com/fazibear/colorize
gem 'terser'                     # Ruby wrapper for Terser JavaScript compressor (nodejs script)
gem 'httpx'                      # HTTP client -- https://gitlab.com/os85/httpx OR https://github.com/HoneyryderChuck/httpx
                                 # https://honeyryderchuck.gitlab.io/httpx/wiki/home.html | https://honeyryderchuck.gitlab.io/httpx/rdoc/

# image manipulation  ==>         https://github.com/janko/image_processing
# used by ActiveStorage variants: https://guides.rubyonrails.org/active_storage_overview.html#transforming-images
# api documentation:              https://github.com/janko/image_processing/blob/master/doc/vips.md#readme
#                                 https://rubydoc.info/gems/ruby-vips/Vips/Image#webpsave-instance_method
#                                 https://github.com/libvips/ruby-vips/blob/master/lib/vips/methods.rb
#                                 https://www.libvips.org/API/current/func-list.html
gem 'image_processing', '~> 1.2', require: %w[ ruby-vips image_processing ]

# https://github.com/westonplatter/phashion -- pHash: image perceptual hashing
#   using a custom version because the original author still hasn't updated the
#   official gem with the latest patch:
#   => https://github.com/westonplatter/phashion/issues/90#issuecomment-1942376596
ENV['PHASHION_USE_GITHUB_SRC'] ?
  gem('phashion', '~> 1.2', github: 'ryoga-chan/phashion') :
  gem('phashion', '~> 1.2', source: 'https://rubygems.pkg.github.com/ryoga-chan')

#gem 'bootsnap', require: false  # Reduces boot times through caching; required in config/boot.rb

group :development do
  gem 'debug', platforms: %i[ mri windows ] # https://guides.rubyonrails.org/debugging_rails_applications.html#debugging-with-the-debug-gem
  gem 'rails-erd'                # DB ER diagram -- https://github.com/voormedia/rails-erd
  gem 'rails_real_favicon'       # https://realfavicongenerator.net/favicon/ruby_on_rails
                                 # https://github.com/RealFaviconGenerator/rails_real_favicon
  gem 'rubocop-rails-omakase', require: false # see .rubocop.yml -- https://github.com/rails/rubocop-rails-omakase/
  gem 'amazing_print'#, require: 'amazing_print'
end
