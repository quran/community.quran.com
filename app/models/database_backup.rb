# frozen_string_literal: true

# == Schema Information
#
# Table name: database_backups
#
#  id         :integer          not null, primary key
#  file       :string
#  size       :string
#  database_name :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class DatabaseBackup < ApplicationRecord
  mount_uploader :file, DatabaseBackupUploader
end
