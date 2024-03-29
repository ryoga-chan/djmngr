# This file was generated by rails_favicon_generator, from https://realfavicongenerator.net/

# It makes files with .webmanifest extension first class files in the asset
# pipeline. This is to preserve this extension, as is it referenced in a call
# to asset_path in the _favicon.html.erb partial.
Rails.application.config.assets.configure do |env|
  # https://github.com/rails/sprockets/blob/main/guides/extending_sprockets.md#register-mime-types
  # https://github.com/rails/sprockets/blob/main/guides/extending_sprockets.md#adding-erb-support-to-your-extension
  if Sprockets::VERSION.to_i >= 4
    # parse site.webmanifest.erb -- https://github.com/RealFaviconGenerator/rails_real_favicon/issues/35#issuecomment-551150699
    env.register_mime_type    'application/manifest+json', extensions: %w[ .webmanifest .webmanifest.erb ]
    env.register_preprocessor 'application/manifest+json', Sprockets::ERBProcessor
    # parse browserconfig.xml.erb -- https://github.com/RealFaviconGenerator/rails_real_favicon/issues/35#issuecomment-551186572
    env.register_mime_type    'application/xml', extensions: %w[ .xml .xml.erb ]
    env.register_preprocessor 'application/xml', Sprockets::ERBProcessor
  else
    env.register_mime_type    'application/manifest+json', extensions: %w[ .webmanifest ]
  end
end
