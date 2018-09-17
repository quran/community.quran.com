class ExportQuranBridges < ApplicationJob
  queue_as :default
  STORAGE_PATH = "public/exported_bridges"
  
  def perform(original_file_name=nil)
    original_file_name ||= 'bridges.db'
    
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
    BSurah.establish_connection connection_config(file_path)
    BAyah.establish_connection connection_config(file_path)
    
    # Object.connection.execute "CREATE VIRTUAL TABLE objects using fts3( id integer, name string)"
    BSurah.connection.execute "CREATE TABLE surah(surah_number integer, name_english string, name_arabic string, en_translated_name string, ayah_count integer, revelation_place string, revelation_order integer, bismillah_pre boolean, pages string, primary key(surah_number))"

    BAyah.connection.execute "CREATE TABLE ayah(ayah_number integer,surah_id integer, page integer, arabic text,ayah_key string, id integer, primary key(id))"


    BSurah.table_name         = 'surah'
    BAyah.table_name = 'ayah'
    
    #ObjectProperty.connection.execute "CREATE  INDEX 'index_objects_properties' ON 'objects_properties' ('version')"
    #ObjectFilter.connection.execute "CREATE  INDEX 'index_filters' ON 'filters' ('filter')"
  end
  
  def prepare_import_sql()
    Chapter.order('chapter_number asc').each do |chapter|
      BSurah.create({
                     surah_number: chapter.chapter_number,
                     name_arabic:  chapter.name_arabic,
                     name_english: chapter.name_complex,
                     en_translated_name:      chapter.translated_names.where(language_id: 38).first.name,
                     ayah_count: chapter.verses_count,
                     revelation_place:  chapter.revelation_place,
                     revelation_order:  chapter.revelation_order,
                     bismillah_pre:  chapter.bismillah_pre,
                     pages: chapter.pages.to_s
                  })

      chapter.verses.order("verse_number asc").each do |verse|
        BAyah.create({
                       ayah_number: verse.verse_number,
                       surah_id: verse.chapter_id,
                       page: verse.page_number,
                       arabic: verse.text_madani,
                       ayah_key: verse.verse_key,
                       id: verse.verse_index
                     })
      end
    end
  end
  
  def connection_config(file_name)
    { adapter:  'sqlite3',
      database: file_name
    }
  end
  
  class BSurah < ActiveRecord::Base
  end

  class BAyah < ActiveRecord::Base
  end
end

