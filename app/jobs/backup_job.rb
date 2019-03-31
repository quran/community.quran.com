# frozen_string_literal: true

class BackupJob < ApplicationJob
  queue_as :default

  def perform(tag=nil)
    if Rails.env.production?
      require "#{Rails.root}/lib/utils/db_backup.rb"
      SystemUtils::DbBackup.run(tag)

      # Delete old dumps
      db_dumps = DatabaseBackup.where(tag: nil).where("created_at < ?", 1.month.ago).order("created_at asc")

      if db_dumps.count > 10
        db_dumps.first(10).delete_all
      end
    end
  end
end
