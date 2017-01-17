# Version of your assets, change this if you want to expire all your assets.
Rails.application.config.assets.version = '1.0'

# Precompile additional assets.
# landing.js, landing.css, and all non-JS/CSS in app/assets folder are already added.

Rails.application.config.assets.precompile += %w( .svg .eot .woff .ttf .woff2 .oft .jpg)
Rails.application.config.assets.paths << Rails.root.join('app', 'assets', 'fonts')
# Rails.application.config.assets.paths << Emoji.images_path
Rails.application.config.assets.initialize_on_precompile = false
Rails.configuration.assets.precompile += %w[serviceworker.js manifest.json]
