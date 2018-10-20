unless ['development', 'test'].include?(Rails.env)
  require 'sentry-raven'
  Raven.configure do |config|
    config.dsn          = ENV['SENTRY_DSN']
    config.environments = ['staging', 'production']
  end
end
