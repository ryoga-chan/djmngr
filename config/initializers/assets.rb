# Be sure to restart your server when you modify this file.

# Version of your assets, change this if you want to expire all your assets.
Rails.application.config.assets.version = "1.0"

# Add additional assets to the asset load path.
# Rails.application.config.assets.paths << Emoji.images_path

# config/initializers/dartsass.rb
base_path  = Rails.root.join('app','assets','stylesheets').to_s
css_assets = Dir[ File.join(base_path, '*.scss').to_s ].sort
Rails.application.config.dartsass.builds = css_assets.inject({}) do |h, f|
  # { input_relative_filename.scss => output_filename.css }
  h.merge! Pathname.new(f).relative_path_from(base_path).to_s => "#{File.basename f, '.scss'}.css"
end

# exclude dart-sass input folder -- https://github.com/rails/propshaft#usage
Rails.configuration.assets.excluded_paths << Rails.root.join('app', 'assets', 'stylesheets')
