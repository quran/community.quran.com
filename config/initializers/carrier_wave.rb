require 'carrierwave/storage/fog'

CarrierWave.configure do |config|
  config.fog_provider = 'fog/aws'                        # required
  config.fog_credentials = {
    provider:              'AWS',                        # required
    aws_access_key_id:     ENV.fetch('AWS_ACCESS_KEY'){'AKIAISY3TKAPVX5DHPHA'},        # required unless using use_iam_profile
    aws_secret_access_key: ENV.fetch('AWS_ACCESS_KEY_SECRET'){'`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`'}, # required unless using use_iam_profile
    use_iam_profile:       true,                         # optional, defaults to false
    region:                'us-east-2'            # us-east (ohio)
  }
  config.fog_directory  = 'com.quran.database.backup'            # required
  config.fog_public     = false                                                 # optional, defaults to true
  config.fog_attributes = { cache_control: "public, max-age=#{2.days.to_i}" } # optional, defaults to {}
end

