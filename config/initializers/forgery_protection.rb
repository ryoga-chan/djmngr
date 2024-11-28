Rails.application.configure do
  # forgery protection not needed for an intranet app
  config.action_controller.allow_forgery_protection = false

  # fix form sumit error when running `bin/rails s -b 0.0.0.0`
  # and sumitting a form from the ereader
  # https://github.com/rails/rails/issues/22965#issuecomment-172983268
  #config.action_controller.forgery_protection_origin_check = false
end
