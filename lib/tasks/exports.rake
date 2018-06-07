# frozen_string_literal: true

namespace :exports do
  task export_wbw_for_mobile: :environment do
    #
    # style,resource,source,author,tafsir,surah_infos,
    # translation,resource_api_version,reciter,ar_internal_metadata,
    # audio_files,authors,chapter_infos,chapters,char_types,
    # data_sources,foot_notes,juzs,images,image,languages,
    # media_contents,recitation_styles,recitations,reciters,
    # resource_contents,roots,schema_migrations,tafsirs,text,
    # translated_names,word_font,tokens,topics,word_translation,
    # translations,transliterations,word,verse_lemmas,
    # verse_roots,verse_stems,verses,view,word_corpus,
    # word_corpuses,word_roots,word_transliteration,word_lemmas,
    # word_lemma,word_root,word_stem,ayah,file,token,recitation,
    # char_type,tafsir_ayah,lemma,root,transliteration,surah,words,
    # lemmas,stems,word_stems,language,stem,arabic_transliterations"
    #
    # Tables to remove:
    #
    
    class WordInfo < ApplicationRecord
    end
    
    class WordTiming < ApplicationRecord
    end

    STORAGE_PATH = "public/exported_databses"
    file_path = "#{STORAGE_PATH}/#{Time.now.to_i}"
    require 'fileutils'
    FileUtils::mkdir_p file_path

    prepare_db_and_tables("#{file_path}/words_info.db")
    prepare_table_data
    
    # zip the file
    `bzip2 #{file_path}/words_info.db`
  end

  def prepare_table_data
    Verse
      .includes(:audio_files, words: [:en_translation, :ur_translation, :bn_translation, :id_translation, :lemma, :stem, :root])
      .order('verse_number asc')
      .find_each do |verse|
    
      verse.words.each do |word|
        WordInfo.create({
                          sura_id:        verse.chapter_id,
                          ayah_id:        verse.verse_number,
                          word_id:        word.id,
                          word_position:  word.position,
                          en_translation: word.en_translation&.text,
                          ur_translation: word.ur_translation&.text,
                          id_translation: word.id_translation&.text,
                          bn_translation: word.bn_translation&.text,
                          stem:           word.stem&.text_madani,
                          lemma:          word.lemma&.text_madani,
                          root:           word.root&.value,
                          text_madani:    word.text_madani,
                          text_simple:    word.text_simple,
                          word_type:      word.char_type_name,
                          glyph:          word.code_hex,
                          glyph_v3:       word.code_hex_v3,
                          page:           word.page_number,
                          key:            "#{verse.verse_key}:#{word.position}"
                        })
      end

      verse.audio_files.each do |audio|
        next if audio.segments.blank?
        
        segments = audio.segments
        i=0
        
        verse.words.order('position asc').each do |word|
          if word.char_type_name == 'word'
            next unless segments[i]
            WordTiming.create({
                                sura_id:       verse.chapter_id,
                                ayah_id:       verse.verse_number,
                                word_id:       word.id,
                                word_position: word.position,
                                qari:          audio.recitation_id,
                                start_time:    segments[i][2].to_i,
                                end_time:      segments[i][3].to_i,
                                key:           "#{verse.verse_key}:#{word.position}"
                              })
            i+=1
          end
        end
      end
      
      puts verse.id
    end
  end

  def prepare_db_and_tables(file_path)
    WordInfo.establish_connection connection_config(file_path)
    WordTiming.establish_connection connection_config(file_path)

    WordInfo.connection.execute "CREATE TABLE words( sura_id integer, ayah_id integer, word_id integer, word_position integer, en_translation string, ur_translation string, bn_translation string, id_translation string, stem string, lemma string, root string, text_madani string, text_simple string, glyph string, glyph_v3 string, word_type string, page integer, key string)"
    WordInfo.connection.execute "CREATE TABLE words_timings( sura_id integer, ayah_id integer, word_id integer, word_position integer, qari integer, start_time integer, end_time integer, key string)"

    WordInfo.table_name = 'words'
    WordTiming.table_name = 'words_timings'
  end

  def connection_config(file_name)
    { adapter: 'sqlite3',
      database: file_name
    }
  end
end
