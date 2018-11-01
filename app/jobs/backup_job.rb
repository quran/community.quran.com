# frozen_string_literal: true

class BackupJob < ApplicationJob
  queue_as :default

  def perform
    if Rails.env.production?
      require "#{Rails.root}/lib/utils/db_backup.rb"
      SystemUtils::DbBackup.run

      # Delete old dumps
      DatabaseBackup.where("created_at < ?", 1.month.ago).delete_all
    end
  end
end
