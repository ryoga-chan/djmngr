LOGRAGE_EXCLUDED_PARAMS = Rails.application.config.filter_parameters +
                          %w[ controller action format id ]

Rails.application.configure do
  case Rails.env.to_sym
    when :production
      logger_args = ENV['PUMA_DAEMON'] \
        ? [File.join(Dir.tmpdir(), "#{config.proctitle}-server.log"), 2]
        : [STDOUT]
      unless Rails.const_defined?(:Console) || defined?(Rake)
        puts "* Logging to #{logger_args.first.inspect}"
      end
      config.logger = ActiveSupport::Logger.new(*logger_args)

      config.lograge.enabled = true

      config.lograge.custom_options = lambda{|event|
        { params: event.payload[:params].except(*LOGRAGE_EXCLUDED_PARAMS).inspect }
      }
    
    when :development
      # Log to STDOUT by default (copied from config/environments/production.rb)
      config.logger = ActiveSupport::Logger.new(STDOUT)
        .tap  { |logger| logger.formatter = ::Logger::Formatter.new }
        .then { |logger| ActiveSupport::TaggedLogging.new(logger) }
  end
end
