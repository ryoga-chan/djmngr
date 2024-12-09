LOGRAGE_EXCLUDED_PARAMS = Rails.application.config.filter_parameters +
                          %w[ controller action format id ]

Rails.application.configure do
  config.lograge.enabled = true

  config.lograge.custom_options = lambda{|event|
    { params: event.payload[:params].except(*LOGRAGE_EXCLUDED_PARAMS).inspect }
  }
end if Rails.env.production?
