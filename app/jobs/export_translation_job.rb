class ExportTranslationJob < ApplicationJob
  queue_as :default
  STORAGE_PATH = "public/exported_databses"

  def perform(resource_id, original_file_name)
    file_name = original_file_name.chomp('.db')

    file_path = "#{STORAGE_PATH}/#{Time.now.to_i}"
    require 'fileutils'
    FileUtils::mkdir_p file_path

    prepare_db("#{file_path}/#{file_name}.db")

    ExportRecord.connection.execute " INSERT INTO verses (sura, ayah, text)
                                     VALUES #{prepare_import_sql(resource_id)}
                                   "
    # zip the file
    `bzip2 #{file_path}/#{file_name}.db`

    # return the db file path
    "#{file_path}/#{file_name}.db.bz2"
  end

  def prepare_db(file_path)
    ExportRecord.establish_connection connection_config(file_path)
    ExportRecord.connection.execute "CREATE VIRTUAL TABLE verses using fts3( sura integer, ayah integer, text text, primary key(sura, ayah ))"
    ExportRecord.connection.execute "CREATE TABLE properties( property text, value text )"
    ExportRecord.connection.execute "INSERT INTO properties(property, value) VALUES ('schema_version', 2), ('text_version', 1)"
    ExportRecord.table_name = 'verses'
  end

  def prepare_import_sql(resource_id)
    Verse.eager_load(:translations).where('translations.resource_content_id': resource_id).map do |v|
      translation = ExportRecord.connection.quote(v.translations.first.text)
      "(#{v.chapter_id}, #{v.verse_number}, #{translation})"
    end.join(',')
  end

  def connection_config(file_name)
    { adapter: 'sqlite3',
      database: file_name
    }
  end

  class ExportRecord < ActiveRecord::Base
  end
end
