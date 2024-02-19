LOGRAGE_EXCLUDED_PARAMS = Rails.application.config.filter_parameters +
                          %w[ controller action format id ]

Rails.application.configure do
  config.lograge.enabled = true

  config.lograge.custom_options = lambda{|event|
    event.payload[:params].except(*LOGRAGE_EXCLUDED_PARAMS)
  }
end if Rails.env.production?
