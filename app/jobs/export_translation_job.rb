class ExportTranslationJob < ApplicationJob
  queue_as :default
  STORAGE_PATH = "public/assets/exported_databses"
  SEE_MORE_REF_REGEXP = Regexp.new('(?<ref>\d+:\d+)')
  TAG_SANITIZER = Rails::Html::WhiteListSanitizer.new

  def perform(resource_id, original_file_name)
    whitelisted_tags = if (resource_id == 149)
                         %w(span b)
                       else
                         []
                       end

    resource_content = ResourceContent.find(resource_id)


    file_name = (original_file_name.presence || resource_content).chomp('.db')

    file_path = "#{STORAGE_PATH}/#{Time.now.to_i}"
    require 'fileutils'
    FileUtils::mkdir_p file_path

    prepare_db("#{file_path}/#{file_name}.db")

    ExportRecord.connection.execute("INSERT INTO verses (sura, ayah, text)
                                     VALUES #{prepare_import_sql(resource_content, whitelisted_tags)}")
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
  end

  def prepare_import_sql(resource, whitelisted_tags)
    if resource.tafisr?
      Tafsir.where(resource_content: resource).map do |tafsir|
        verse_key = tafsir.verse_key.split(':')
        text = ExportRecord.connection.quote(tafsir.text)
        "(#{verse_key[0]}, #{verse_key[1]}, #{text})"
      end.join(',')
    else
      Verse.eager_load(:translations)
          .order('verses.verse_index ASC')
          .where('translations.resource_content_id': resource.id)
          .map do |v|
        translation = format_translation_text(v.translations.first, whitelisted_tags)
        "(#{v.chapter_id}, #{v.verse_number}, #{translation})"
      end.join(',')
    end
  end

  def format_translation_text(translation, whitelisted_tags = [])
    text = translation.text.gsub('"', '')

    translation.foot_notes.each do |f|
      reg = /<sup foot_note=#{f.id}>\d+<\/sup>/

      text = text.gsub(reg) do
        "[[#{f.text.gsub('"', '')}]]"
      end
    end

    sanitized = TAG_SANITIZER.sanitize(text.to_s.strip, tags: whitelisted_tags, attributes: []).gsub(/[\r\n]+/, "<br/>")
    sanitized = sanitized.gsub(SEE_MORE_REF_REGEXP) do
      "{#{Regexp.last_match(1)}}"
    end

    ExportRecord.connection.quote(sanitized)
  end

  def connection_config(file_name)
    {adapter: 'sqlite3',
     database: file_name
    }
  end

  class ExportRecord < ActiveRecord::Base
  end
end
