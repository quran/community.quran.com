# frozen_string_literal: true

class BackupJob < ApplicationJob
  queue_as :default

  def perform(tag=nil)
    if Rails.env.production?
      require "#{Rails.root}/lib/utils/db_backup.rb"
      Utils::DbBackup.run(tag)

      # Delete old dumps
      db_dumps = DatabaseBackup.where(tag: nil).where("created_at < ?", 1.month.ago).order("created_at asc")

      if db_dumps.count > 30
        # Lets keep first 30 backups. There are 3 dbs, so we're keeping 10 backups for each db
        db_dumps.first(db_dumps.count-30).delete_all
      end
    end
  end
end
