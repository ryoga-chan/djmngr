# Eager load code on boot.
Rails.application.config.eager_load = true if Rails.env.development?
