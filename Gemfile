source 'https://rubygems.org'
ruby '2.7.1'

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '>= 6.0.3.2'
# Use postgresql as the database for Active Record
gem 'pg'
gem 'sqlite3'
gem 'mysql2', require: false
# Use Puma as the app server
gem 'puma', '~> 4.3.5'
# Use SCSS for stylesheets
gem 'sass-rails', '~> 5.0'
# Use Uglifier as compressor for JavaScript assets
gem 'uglifier', '>= 1.3.0'

# See https://github.com/rails/execjs#readme for more supported runtimes
# gem 'therubyracer', platforms: :ruby

gem 'activerecord-import', require: false

# Use jquery as the JavaScript library
gem 'jquery-rails'

# Turbolinks makes navigating your web application faster. Read more: https://github.com/turbolinks/turbolinks
gem 'turbolinks'

# Use Redis adapter to run Action Cable in production
# gem 'redis', '~> 3.0'
# Use ActiveModel has_secure_password
# gem 'bcrypt', '~> 3.1.7'

# Use Capistrano for deployment
# gem 'capistrano-rails', group: :development

# Detect language from text
#gem "cld3"

# Admin panel
#gem 'activeadmin', '~> 2.7.0'
gem 'activeadmin-async_panel'
gem 'activeadmin-searchable_select'
gem 'activeadmin_quill_editor'
gem 'paper_trail', '~> 10.3.1'

gem 'bootstrap-kaminari-views'
# Bootstrap view helpers
gem 'twitter-bootstrap-rails'

gem 'nokogiri', '1.11.0'
gem 'pdf-reader'

# authentication
gem 'devise'
gem 'newrelic_rpm'

# Generate embed code and get metadata of video etc
# gem 'video_info'

# github.com/JeremyGeros/differ
gem 'diffy'
# For Slug generation
gem 'babosa', require: false

group :development, :test do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'byebug', platform: :mri
end

group :staging do
  # exception tracking
  gem "sentry-raven", require: false
end

group :development do
  # Gems we used for optimizing fonts. Might need them in future.
  # gem 'convert_font'
  # gem 'svg_optimizer'
  # gem 'htmlentities'
  
  # Access an IRB console on exception pages or by using <%= console %> anywhere in the code.
  gem 'web-console'
  gem 'listen', '~> 3.0.5'
  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  # gem 'spring'
  # gem 'spring-watcher-listen', '~> 2.0.0'
  gem 'pry-byebug'
  gem 'annotate'
  gem 'pry-rails'
  gem 'mechanize', require: false
end

gem 'sidekiq', '~> 5.2.2'
gem 'sidekiq-scheduler', '~> 3.0.1'
gem 'sinatra', require: false
gem 'carrierwave', '~> 1.3.2'
gem "fog-aws"
gem "rest-client"
gem 'tzinfo-data'
