class ExportWordsJob < ApplicationJob
  queue_as :default
  STORAGE_PATH = "public/exported_databses"
  
  def perform(original_file_name)
    file_name = original_file_name.chomp('.db')
    file_path = "#{STORAGE_PATH}/#{Time.now.to_i}"
    require 'fileutils'
    FileUtils::mkdir_p file_path
    
    prepare_db("#{file_path}/#{file_name}.db")
    
    prepare_import_sql
   
    # zip the file
    `bzip2 #{file_path}/#{file_name}.db`
    
    # return the db file path
    "#{file_path}/#{file_name}.db.bz2"
  end
  
  def prepare_db(file_path)
    ExportRecord.establish_connection connection_config(file_path)
    ExportRecord.connection.execute("CREATE TABLE words(sura integer,ayah integer, word_position integer,
                                      en_translation text, ur_translation text, bn_translation text, id_translation text,
                                      transliteration text, text_madani text, glyph text, word_type text, audio_url text,
                                      primary key(sura, ayah, word_position))")
    ExportRecord.table_name = 'words'
  end
  
  def prepare_import_sql()
    Word.includes(:transliterations, :en_translation, :ur_translation, :bn_translation, :id_translation).find_each do |word|
      en_translation    = ExportRecord.connection.quote(word.en_translation&.text)
      ur_translation    = ExportRecord.connection.quote(word.ur_translation&.text)
      bn_translation    = ExportRecord.connection.quote(word.bn_translation&.text)
      id_translation    = ExportRecord.connection.quote(word.id_translation&.text)

      w_type         = ExportRecord.connection.quote(word.char_type_name)
      code           = ExportRecord.connection.quote(word.code_v3)
      chapter, verse = word.verse_key.split(':')
      translitration = ExportRecord.connection.quote(word.transliterations.first&.text)
      text           = ExportRecord.connection.quote(word.text_madani)
      audio          = ExportRecord.connection.quote(word.audio_url)
      values          = "(#{chapter}, #{verse}, #{word.position}, #{en_translation}, #{ur_translation}, #{bn_translation},
                         #{id_translation}, #{translitration}, #{text}, #{code}, #{w_type}, #{audio})"
      begin
        ExportRecord.connection.execute("INSERT INTO words (sura, ayah, word_position, en_translation, ur_translation,
                                         bn_translation, id_translation, transliteration,text_madani, glyph, word_type, audio_url) VALUES #{values}")
        
      rescue Exception => e
      end
    end
  end
  
  def connection_config(file_name)
    { adapter:  'sqlite3',
      database: file_name
    }
  end
  
  class ExportRecord < ActiveRecord::Base
  end
end
