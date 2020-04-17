# https://www.elastic.co/guide/en/elasticsearch/reference/7.3/analysis-synonym-tokenfilter.html
#

class WordCorpusData < ActiveRecord::Base
end

namespace :es_synonyms do
  task export: :environment do
    File.open 'quran_word_synonym.txt', 'wb' do |file|
      Synonym.find_each do |s|
        file << "#{s.synonyms.join(', ')} => #{s.text}\n"
      end
    end
  end

  task generate: :environment do
    WordSynonym.delete_all
    Synonym.delete_all

    def remove_dialectic(text)
      simple = text.gsub(/\u06E2|\uE022|\u06DA|\u06E4|\u06D9|\u06D6| ۖ||ۙ |\u0651|\uE01C|\u06E1|\uE01E|\u06DA|\u0615|\u06E6|\ufe80|\u06E5|\u064B|\u0670|\u0FBCx|\u0FB5x|\u0FBB6|\u0FE7x|\u0FC62|\u0FC61|\u0FC60|\u0FDF0|\u0FDF1|\u0066D|\u0061F|\u060F|\u060E|\u060D|\060C|\u060B|\u064C|\u064D|\u064E|\u064F|\u0650|\u0651|\u0652|\u0653|\u0654|\u0655|\u0656|\0657|\u0658/, '')
      simple.gsub(/\u0671|\u0625|\u0623/, 'ا').strip
    end

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
      verse_transliterations = verse.translations.where(resource_content_id: 57).first.text.split(/\s+/)
      pos = 1

      verse.words.words.order('position asc').each do |word|
        next if word.text_madani.blank? || 'word' != word.char_type_name

        word_info = WordCorpusData.where(surah: verse.chapter_id, ayah: verse.verse_number, word: pos).first
        lema = word_info&.lemma

        lemmas = [lema]
        stems = [] #word.stems.pluck(:text_madani, :text_clean)
        root = [word_info&.root_ar]
        indopak = [word.text_imlaei, word.text_madani]
        transliteration = word.transliterations.where(language_name: 'english').pluck(:text)

        synonyms = lemmas + stems + root + indopak

        simple = synonyms.flatten.compact.map do |text|
          remove_dialectic(text.to_s)
        end.uniq

        key = remove_dialectic(word.text_madani)
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

    File.open 'quran_word_synonym2.txt', 'wb' do |file|
      uniq_words.keys.each do |key|
        value = uniq_words[key][0].flatten.uniq.select { |t| t.to_s.length > 1 }
        value = value - [key]

        transliterations = uniq_words[key][1].flatten.uniq.select { |t| t.to_s.length > 1 }
        tr_normalized = transliterations.map do |t|
          normalize(t)
        end

        transliterations = tr_normalized.flatten.compact.uniq #(transliterations + tr_normalized).flatten.compact.uniq

        all_synonyms = (transliterations + value).flatten
        all_synonyms.each do |s|
          puts s

          synonym = Synonym.where(text: key).first_or_create
          synonym.update(synonyms: all_synonyms)

          uniq_words[key][2].each do |w|
            WordSynonym.where(word_id: w, synonym_id: synonym.id).first_or_create
          end
        end

        file << "#{transliterations.join(', ')}"
        if value.present?
          file << ",#{value.join(', ')}"
        end
        file << " => #{key}\n"
      end
    end

    File.open 'quran_word_synonym3.txt', 'wb' do |file|
      uniq_words.keys.each do |key|
        value = uniq_words[key][0].flatten.map do |t|
          remove_dialectic(t)
        end.uniq.select { |t| t.to_s.length > 1 }
        value = value - [key]
        transliterations = uniq_words[key][1].flatten.uniq.select { |t| t.to_s.length > 1 }

        tr_normalized = transliterations.map do |t|
          normalize(t)
        end

        transliterations = (transliterations + tr_normalized).flatten.compact.uniq

        all_synonyms = (transliterations + value).flatten

        synonym = Synonym.where(text: key).first_or_create
        synonym.update(synonyms: all_synonyms)

        uniq_words[key][2].each do |w|
          WordSynonym.where(word_id: w, synonym_id: synonym.id).first_or_create
        end

        file << "#{transliterations.join(', ')}"
        if value.present?
          file << ",#{value.join(', ')}"
        end
        file << " => #{key}\n"
      end
    end

    puts "done"
  end
end


#
# ayah, lemma, roots, stem, stems,  word, word_font, token, tokens,  text, , verse_lemmas, verse_roots, verse_stems, verses,
# view, word_corpus, word_corpuses, word_roots, , word_stems, word_lemmas, word_lemma, word_root, word_stem,  words, lemmas, root