require_relative "boot"

require "rails"
# Pick the frameworks you want:
require "active_model/railtie"
require "active_job/railtie"
require "active_record/railtie"
require "active_storage/engine"
require "action_controller/railtie"
require "action_mailer/railtie"
# require "action_mailbox/engine"
# require "action_text/engine"
require "action_view/railtie"
# require "action_cable/engine"
# require "rails/test_unit/railtie"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Djmngr
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 7.0

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    
    #config.eager_load_paths << Rails.root.join('lib', 'app')

    # Don't generate system test files.
    config.generators.system_tests = nil
    
    # forgery protection not needed for an intranet app
    config.action_controller.allow_forgery_protection = false
    # fix form sumit error when running `bin/rails s -b 0.0.0.0`
    # and sumitting a form from the ereader
    # https://github.com/rails/rails/issues/22965#issuecomment-172983268
    #config.action_controller.forgery_protection_origin_check = false
    
    # https://pawelurbanek.com/rails-gzip-brotli-compression
    # test with: curl -siIH "Accept-Encoding: gzip, deflate, br" "http://localhost:3000" | egrep "^Content-Encoding"
    config.middleware.use Rack::Deflater
    config.middleware.use Rack::Brotli
  end
end
