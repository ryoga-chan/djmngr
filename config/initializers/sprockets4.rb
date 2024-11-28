# fix "Asset compilation stalls with sprockets v4" @ https://github.com/rails/sprockets/issues/640#issuecomment-546948748
Sprockets.export_concurrent = false

Rails.application.configure do
  config.assets.css_compressor = :scss
  config.assets.js_compressor  = :terser
end if Rails.env.production?
