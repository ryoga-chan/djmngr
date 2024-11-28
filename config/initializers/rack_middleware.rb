#Rails.application.configure do
#  # Gemfile add: gem 'rack-brotli', '~> 1.2' # enable brotli compression
#  #
#  # https://pawelurbanek.com/rails-gzip-brotli-compression
#  # test with: curl -siIH "Accept-Encoding: gzip, deflate, br" "http://localhost:3000" | egrep "^Content-Encoding"
#  # !!each one SEGFAULTs using send_file!!
#  #config.middleware.use Rack::Deflater
#  #config.middleware.use Rack::Brotli
#end
