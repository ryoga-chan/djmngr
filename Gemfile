source 'https://rubygems.org'

# HOWTO: update gems and remove old versions
#   bundle update
#   gem cleanup

ruby '>= 3.0.0'

gem 'rails',       '~> 8.0.1',   # to use edge: gem 'rails', github: 'rails/rails', branch: 'main'
  require: %w[ shellwords open-uri pp open3 ]
gem 'sqlite3',     '~> 2.3'      # sqlite3 database for Active Record
gem 'puma',        '~> 6.5'      # puma web server -- https://github.com/puma/puma
gem 'puma-daemon', '~> 0.3', require: false # daemonize puma -- https://github.com/kigster/puma-daemon
gem 'tzinfo-data', platforms: %i[ windows jruby ] # zoneinfo files for Windows
gem 'propshaft'                  # asset pipeline -- https://github.com/rails/propshaft
gem 'importmap-rails'            # use JS with ESM import maps -- https://github.com/rails/importmap-rails
gem 'dartsass-rails'             # use Dart SASS -- https://github.com/rails/dartsass-rails
gem 'haml-rails',  '~> 2.1'      # https://haml.info
gem 'kaminari',    '~> 1.2'      # pagination -- https://github.com/kaminari/kaminari

gem 'lograge',     '~> 0.14'     # greppable logs -- https://github.com/roidrage/lograge
gem 'marcel',      '~> 1.0'      # mime type of files -- https://github.com/rails/marcel
gem 'progressbar', '~> 1.13'     # cli progressbar -- https://github.com/jfelchner/ruby-progressbar
gem 'rubyzip',     '~> 2.3', require: 'zip' # manage ZIP files -- https://github.com/rubyzip/rubyzip
gem 'paper_trail', '~> 16.0'     # track model changes -- https://github.com/paper-trail-gem/paper_trail
gem 'colorize',    '~> 1.1', require: 'colorized_string' # terminal colors -- https://github.com/fazibear/colorize
gem 'httpx',       '~> 1.3'      # HTTP client -- https://gitlab.com/os85/httpx OR https://github.com/HoneyryderChuck/httpx
                                 # https://honeyryderchuck.gitlab.io/httpx/wiki/home.html | https://honeyryderchuck.gitlab.io/httpx/rdoc/

# https://nokogiri.org/tutorials/installing_nokogiri.html#how-can-i-avoid-using-a-precompiled-native-gem
gem 'nokogiri',    '~> 1.18', force_ruby_platform: true # HTML/XML parser -- https://github.com/sparklemotion/nokogiri

gem 'fiddle',      '~> 1.1'      # libffi wrapper -- https://github.com/ruby/fiddle
gem 'kakasi',      '~> 1.0'      # kanji kana simple inverter -- https://github.com/knu/kakasi_ffi

# image manipulation  ==>         https://github.com/janko/image_processing
# used by ActiveStorage variants: https://guides.rubyonrails.org/active_storage_overview.html#transforming-images
# api documentation:              https://github.com/janko/image_processing/blob/master/doc/vips.md#readme
#                                 https://rubydoc.info/gems/ruby-vips/Vips/Image#webpsave-instance_method
#                                 https://github.com/libvips/ruby-vips/blob/master/lib/vips/methods.rb
#                                 https://www.libvips.org/API/current/func-list.html
gem 'image_processing', '~> 1.13', require: %w[ ruby-vips image_processing ]

# https://github.com/westonplatter/phashion -- pHash: image perceptual hashing
#   using a custom version because the original author still hasn't updated the
#   official gem with the latest patch:
#   => https://github.com/westonplatter/phashion/issues/90#issuecomment-1942376596
ENV['PHASHION_USE_GITHUB_SRC'] ?
  gem('phashion', '~> 1.2', github: 'ryoga-chan/phashion') :
  gem('phashion', '~> 1.2', source: 'https://rubygems.pkg.github.com/ryoga-chan')

#gem "solid_cache"               # database-backed adapter for Rails.cache
#gem "solid_queue"               # database-backed adapter for Active Job
#gem "solid_cable"               # database-backed adapter for Action Cable
#gem "thruster", require: false  # Add HTTP asset caching/compression and X-Sendfile acceleration to Puma [https://github.com/basecamp/thruster/]
#gem 'bootsnap', require: false  # Reduces boot times through caching; add `require "bootsnap/setup"` in config/boot.rb

group :development do
  # https://guides.rubyonrails.org/debugging_rails_applications.html#debugging-with-the-debug-gem
  gem 'debug', platforms: %i[ mri windows ], require: "debug/prelude"
  gem 'rails-erd'                # DB ER diagram -- https://github.com/voormedia/rails-erd
  gem 'rubocop-rails-omakase', require: false # see .rubocop.yml -- https://github.com/rails/rubocop-rails-omakase/
  gem 'amazing_print'            # https://github.com/amazing-print/amazing_print
end
