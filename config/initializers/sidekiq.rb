# frozen_string_literal: true
Sidekiq::Extensions.enable_delay!
Sidekiq.logger.level = Logger::WARN

redis_url = ENV.fetch('REDIS_URL') {'localhost:6379'}

Sidekiq.configure_server do |config|
  config.redis = { url: redis_url }
end

Sidekiq.configure_client do |config|
  config.redis = { url: redis_url }
end
