# https://www.elastic.co/guide/en/elasticsearch/reference/7.3/analysis-synonym-tokenfilter.html
#

class WordCorpusData < ActiveRecord::Base
end

namespace :es_synonyms do
  task export: :environment do
    require 'fileutils'
    FileUtils::mkdir_p 'public/assets'

    file_name = 'public/assets/quran_word_synonym.txt'

    File.open 'quran_word_synonym.txt', 'wb' do |file|
      Synonym.find_each do |s|
        file << "#{s.synonyms.join(', ')}\n"
      end
    end

    puts "done #{file_name}"
  end

  task generate: :environment do
    WordSynonym.delete_all
    Synonym.delete_all

    def normalize(str)
      str = str.tr("ÀÁÂÃÄÅàáâãäåĀāĂăĄąÇçĆćĈĉĊċČčÐðĎďĐđḍÈÉÊËèéêëĒēĔĕĖėĘęĚěĜĝĞğĠġĢģĤĥĦħÌÍÎÏìíîïĨĩĪīĬĭĮįİıĴĵĶķĸĹĺĻļĽľĿŀŁłÑñŃńŅņŇňŉŊŋÒÓÔÕÖØòóôõöøŌōŎŏŐőŔŕŖŗŘřŚśŜŝŞşŠšȘșſŢţŤťŦŧȚțÙÚÛÜùúûüŨũŪūŬŭŮůŰűŲųŴŵÝýÿŶŷŸŹźŻżŽž", "AAAAAAaaaaaaAaAaAaCcCcCcCcCcDdDdDddEEEEeeeeEeEeEeEeEeGgGgGgGgHhHhIIIIiiiiIiIiIiIiIiJjKkkLlLlLlLlLlNnNnNnNnnNnOOOOOOooooooOoOoOoRrRrRrSsSsSsSsSssTtTtTtTtUUUUuuuuUuUuUuUuUuUuWwYyyYyYZzZzZz  ")
      str.tr("'ʿ", '').downcase
    end

    def prepare_db_and_tables(file_path)
      WordCorpusData.establish_connection connection_config(file_path)
      WordCorpusData.table_name = 'corpus'
    end

    def connection_config(file_name)
      {adapter: 'sqlite3',
       database: file_name
      }
    end

    prepare_db_and_tables("data/corpus.db")

    uniq_words = {}
    Verse.unscoped.order('verse_index asc').each do |verse|
      pos = 1

      verse.words.words.order('position asc').each do |word|
        next if word.text_madani.blank? || 'word' != word.char_type_name

        word_info = WordCorpusData.where(surah: verse.chapter_id, ayah: verse.verse_number, word: pos).first
        lema = word_info&.lemma

        lemmas = [lema]
        root = [word_info&.root_ar]
        scripts = [word.text_imlaei,  word.text_indopak, word.text_simple]
        transliteration = word.transliterations.where(language_name: 'english').pluck(:text)

        synonyms = lemmas  + root + scripts

        simple = synonyms.flatten.compact.map do |text|
          text.to_s.remove_dialectic
        end.uniq

        key = word.text_madani.to_s.remove_dialectic
        uniq_words[key] ||= []
        uniq_words[key][0] ||= []
        uniq_words[key][0] << simple
        uniq_words[key][1] ||= []
        uniq_words[key][1] << transliteration
        uniq_words[key][2] ||= []

        uniq_words[key][2] << word.id

        puts word.location
        pos += 1
      end
    end

    file_name = 'public/assets/quran_word_synonym_1.txt'
    require 'fileutils'
    FileUtils::mkdir_p 'public/assets'

    File.open file_name, 'wb' do |file|
      uniq_words.keys.each do |key|
        scripts = uniq_words[key][0] + [key]

        value = scripts.flatten.map do |t|
          remove_dialectic(t)
        end.uniq.select { |t| t.to_s.length > 1 }

        transliterations = uniq_words[key][1].flatten.uniq.select { |t| t.to_s.length > 1 }

        tr_normalized = transliterations.map do |t|
          normalize(t)
        end

        # transliterations = (transliterations + tr_normalized).flatten.compact.uniq
        # all_synonyms = (transliterations + value).flatten

        all_synonyms = (tr_normalized + value).flatten
        synonym = Synonym.where(text: key).first_or_create
        synonym.update(synonyms: all_synonyms)

        uniq_words[key][2].each do |w|
          WordSynonym.where(word_id: w, synonym_id: synonym.id).first_or_create
        end

        file << "#{all_synonyms.join(', ')}\n"
      end
    end

    puts "done #{file_name}"
  end
end


#
# ayah, lemma, roots, stem, stems,  word, word_font, token, tokens,  text, , verse_lemmas, verse_roots, verse_stems, verses,
# view, word_corpus, word_corpuses, word_roots, , word_stems, word_lemmas, word_lemma, word_root, word_stem,  words, lemmas, root