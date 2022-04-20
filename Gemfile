source 'https://rubygems.org'
git_source(:github) { |repo| 'https://github.com/#{repo}.git' }

# HOWTO: update gems and remove old versions
#   bundle update
#   gem cleanup

ruby '3.0.0'

gem 'rails',       '~> 7.0.0',   # to use edge: gem 'rails', github: 'rails/rails', branch: 'main'
  require: %w{ shellwords }
gem 'sqlite3',     '~> 1.4'      # sqlite3 database for Active Record
gem 'puma',        '~> 5.0'      # puma web server -- https://github.com/puma/puma
gem 'rack-brotli', '~> 1.2.0'    # enable brotli compression
gem 'bcrypt',      '~> 3.1.7'    # ActiveModel's has_secure_password -- https://guides.rubyonrails.org/active_model_basics.html#securepassword
gem 'sassc-rails'                # sass to process CSS
gem 'sprockets-rails'            # asset pipeline -- https://github.com/rails/sprockets-rails
gem 'tzinfo-data', platforms: %i[ mingw mswin x64_mingw jruby ] # zoneinfo files for Windows
gem 'haml-rails',  '~> 2.0'      # https://haml.info
gem 'kaminari'                   # pagination -- https://github.com/kaminari/kaminari
gem 'kakasi'                     # kanji kana simple inverter -- https://github.com/knu/kakasi_ffi
gem 'progressbar'                # cli progressbar -- https://github.com/jfelchner/ruby-progressbar
#gem 'ferret', '0.11.9.0', source: 'https://rubygems.pkg.github.com/acavalin' # https://github.com/acavalin/ferret

# image manipulation  ==>         https://github.com/janko/image_processing
# used by ActiveStorage variants: https://guides.rubyonrails.org/active_storage_overview.html#transforming-images
# api documentation:              https://github.com/janko/image_processing/blob/master/doc/vips.md#readme
#                                 https://rubydoc.info/gems/ruby-vips/Vips/Image#webpsave-instance_method
gem 'image_processing', '~> 1.2', require: %w{ ruby-vips image_processing }

#gem 'bootsnap', require: false   # Reduces boot times through caching; required in config/boot.rb

group :development do
  gem 'debug', platforms: %i[ mri mingw x64_mingw ] # See https://guides.rubyonrails.org/debugging_rails_applications.html#debugging-with-the-debug-gem
end
