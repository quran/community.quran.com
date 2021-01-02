class ExportTranslationWithFootNoteJob < ApplicationJob
  queue_as :default
  STORAGE_PATH = "public/assets/exported_databses"

  def perform(resource_id, original_file_name)
    resource_content = ResourceContent.find(resource_id)

    file_name = (original_file_name.presence || resource_content.name).chomp('.db')

    file_path = STORAGE_PATH
    require 'fileutils'
    FileUtils::mkdir_p file_path

    prepare_db("#{file_path}/#{file_name}.db")

    author_name = ExportRecord.connection.quote(resource_content.author_name)
    language_name = ExportRecord.connection.quote(resource_content.language.name)
    ExportRecord.connection.execute "INSERT INTO properties(property, value) VALUES ('author_name', #{author_name}), ('language', #{language_name})"

    ExportRecord.connection.execute("INSERT INTO verses (sura, ayah, text)
                                     VALUES #{prepare_import_sql(resource_content)}")

    ExportRecord.connection.execute("INSERT INTO footnotes (id, text)
                                     VALUES #{prepare_footnote_import_sql(resource_content)}")
      # zip the file
      `bzip2 #{file_path}/#{file_name}.db`

      # return the db file path
      "#{file_path}/#{file_name}.db.bz2"
  end

  def prepare_db(file_path)
    ExportRecord.establish_connection connection_config(file_path)
    ExportRecord.connection.execute "CREATE VIRTUAL TABLE verses using fts3( sura integer, ayah integer, text text)"
    ExportRecord.connection.execute "CREATE TABLE properties( property text, value text)"
    ExportRecord.connection.execute "INSERT INTO properties(property, value) VALUES ('schema_version', 2), ('text_version', 1)"
    ExportRecord.table_name = 'verses'

    ExportFootNoteRecord.establish_connection connection_config(file_path)
    ExportFootNoteRecord.connection.execute "CREATE TABLE footnotes ( id integer, text text)"
    ExportRecord.table_name = 'footnotes'
  end

  def prepare_import_sql(resource)
    Verse.eager_load(:translations).
        where('translations.resource_content_id': resource.id)
        .map do |v|
      translation = format_translation_text(v.translations.first)
      "(#{v.chapter_id}, #{v.verse_number}, #{translation})"
    end.join(',')
  end

  def prepare_footnote_import_sql(resource)
    FootNote.where(translation: Translation.where(resource_content_id: resource.id)).map do |footnote|
      text = ExportRecord.connection.quote(footnote.text)

      "(#{footnote.id}, #{text})"
    end.join(',')
  end

  def format_translation_text(translation)
    text = translation.text

    ExportRecord.connection.quote(text)
  end

  def connection_config(file_name)
    {adapter: 'sqlite3',
     database: file_name
    }
  end

  class ExportRecord < ActiveRecord::Base
  end

  class ExportFootNoteRecord < ActiveRecord::Base
  end
end
