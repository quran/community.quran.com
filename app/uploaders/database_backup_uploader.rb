# frozen_string_literal: true

class DatabaseBackupUploader < CarrierWave::Uploader::Base
  storage :fog
end
