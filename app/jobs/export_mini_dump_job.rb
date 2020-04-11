class ExportMiniDumpJob < ApplicationJob
  queue_as :default
  STORAGE_PATH = "public/assets/exported_databses"

  def perform
    file_name = 'mini_dump.sql'

    translation = [131, 54, 39]
    recitation = [7, 8]
    word_translations = [104, 59]

    ExportRecord.establish_connection(connection_config)

    Recitation.where(id: recitation).each do |r|
      ExportedRecitation.create(r.attributes)
    end

    Reciter.find_each do |r|
      ExportedReciter.create r.attributes
    end

    Juz.find_each do |j|
      ExportedJuz.create j.attributes
    end

    ResourceContent.find_each do |r|
      ExportedResourceContent.create(r.attributes)
    end

    TranslatedName.find_each do |r|
      ExportedTranslatedName.create(r.attributes)
    end

    Topic.find_each do |t|
      ExportedTopic.create(t.attributes)
    end

    Language.find_each do |l|
      ExportedLanguage.create(l.attributes)
    end

    en = Language.find_by(iso_code: 'en')
    Chapter.order("chapter_number ASC").each do |c|
      chapter = ExportedChapter.create(c.attributes)

      c.slugs.first(4).each do |s|
        attrs = s.attributes
        attrs['chapter_id'] = chapter.id
        ExportedSLug.create(attrs)
      end

      c.chapter_infos.where(language_id: en).each do |info|
        attrs = info.attributes.except("id")
        attrs['chapter_id'] = chapter.id
        ExportedChapterInfo.create attrs
      end

      c.verses.order('verse_number ASC').first(15).each do |v|
        verse = ExportedVerse.create(v.attributes)

        v.tafsirs.first(2).each do |t|
          ExportedTafsir.create t.attributes
        end

        v.translations.where(resource_content_id: translation).each do |t|
          ExportedTranslation.create(t.attributes)
        end

        v.audio_files.where(recitation_id: recitation).each do |r|
          ExportedAudioFile.create(r.attributes)
        end

        v.words.each do |w|
          ExportedWord.create(w.attributes)

          w.word_translations.where(resource_content_id: word_translations).each do |wt|
            ExportedWordTranslation.create(wt.attributes)
          end

          w.transliterations.each do |wt|
            ExportedTransliteration.create(wt.attributes)
          end
        end
      end
    end
  end

  def connection_config
    {
        adapter: 'postgresql',
        database: 'quran_dev_backup'
    }
  end

  class ExportRecord < ActiveRecord::Base
  end

  class ExportedWord < ExportRecord
    self.table_name = 'words'
  end

  class ExportedChapter < ExportRecord
    self.table_name = 'chapters'
  end

  class ExportedChapterInfo < ExportRecord
    self.table_name = 'chapter_infos'
  end

  class ExportedVerse < ExportRecord
    self.table_name = 'verses'
  end

  class ExportedTranslation < ExportRecord
    self.table_name = 'translations'
  end

  class ExportedTransliteration < ExportRecord
    self.table_name = 'transliterations'
  end

  class ExportedAudioFile < ExportRecord
    self.table_name = 'audio_files'
  end

  class ExportedWord < ExportRecord
    self.table_name = 'words'
  end

  class ExportedWordTranslation < ExportRecord
    self.table_name = 'word_translations'
  end

  class ExportedResourceContent < ExportRecord
    self.table_name = 'resource_contents'
  end

  class ExportedTafsir < ExportRecord
    self.table_name = 'tafsirs'
  end

  class ExportedFootNote < ExportRecord
    self.table_name = 'foot_notes'
  end


  class ExportedJuz < ExportRecord
    self.table_name = 'juzs'
  end

  class ExportedLanguage < ExportRecord
    self.table_name = 'languages'
  end

  class ExportedRecitation < ExportRecord
    self.table_name = 'recitations'
  end

  class ExportedReciter < ExportRecord
    self.table_name = 'reciters'
  end

  class ExportedTopic < ExportRecord
    self.table_name = 'topics'
  end

  class ExportedTranslatedName < ExportRecord
    self.table_name = 'translated_names'
  end

  class ExportedSLug < ExportRecord
    self.table_name = 'slugs'
  end
end
