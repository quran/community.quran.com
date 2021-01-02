namespace :export_basera do

  class ExportRecord < ActiveRecord::Base
  end

  class ExportRecord < ActiveRecord::Base
  end

  class ExportSurahRecord < ExportRecord
  end

  class ExportVerseRecord < ExportRecord
  end

  class ExportWordRecord < ExportRecord
  end

  class ExportTranslationRecord < ExportRecord
  end

  class ExportTransliterationRecord < ExportRecord
  end

  class ExportWordTranslationRecord < ExportRecord
  end

  class ExportFootNoteRecord < ExportRecord
  end

  class ExportJuzRecord < ExportRecord
  end

  class ExportRecitationRecord < ExportRecord
  end

  class ExportAudioFileRecord < ExportRecord
  end

  class ExportResourceRecord < ExportRecord
  end

  class ExportCharTypeRecord < ExportRecord
  end

  class ExportLanguageRecord < ExportRecord
  end

  class ExportAuthorRecord < ExportRecord
  end

  class ExportUrduTransliterationRecord < ExportRecord
  end

  class ExportWordTransliterationRecord < ExportRecord

  end

  def prepare_db()
    ExportRecord.establish_connection connection_config()
    #ExportUrduTransliterationRecord.table_name = "quran_word_urdu_transliteration"
    ExportJuzRecord.table_name = "quran_juz"
    ExportFootNoteRecord.table_name = 'quran_foot_note'
    ExportWordTransliterationRecord.table_name = "quran_word_transliteration"
    ExportTransliterationRecord.table_name = 'quran_transliteration'
    ExportWordTranslationRecord.table_name = 'quran_word_translation'
    ExportTranslationRecord.table_name = 'quran_translation'
    ExportWordRecord.table_name = 'quran_word'
    ExportAudioFileRecord.table_name = "quran_audio_file"
    ExportVerseRecord.table_name = 'quran_ayah'
    ExportSurahRecord.table_name = 'quran_surah'
    ExportRecitationRecord.table_name = "quran_recitation"
    ExportResourceRecord.table_name = "quran_resource_content"
    ExportCharTypeRecord.table_name = "quran_char_type"
    ExportLanguageRecord.table_name = "quran_language"
    ExportAuthorRecord.table_name = "quran_author"
  end

  def connection_config
    {
        adapter: 'mysql2',
        username: 'root',
        database: 'quran_api'
    }
  end

  task run: :environment do
    require 'activerecord-import'

    prepare_db()
    approved_translations = ResourceContent.translations.approved.pluck(:id)

    ExportJuzRecord.delete_all
    Juz.find_each do |j|
      ExportJuzRecord.create(
          id: j.id,
          juz_number: j.juz_number,
          verse_mapping: j.verse_mapping.to_json)
    end

    records = CharType.all.map do |char|
      ExportCharTypeRecord.new(id: char.id, name: char.name, description: char.description.to_s)
    end
    ExportCharTypeRecord.import(records, validate: false)

    records = Language.all.map do |lang|
      ExportLanguageRecord.new(id: lang.id, name_native: lang.native_name, name_english: lang.name, direction: lang.direction, iso_code: lang.iso_code)
    end
    ExportLanguageRecord.import(records, validate: false)

    Author.find_each do |a|
      ExportAuthorRecord.create(id: a.id, name: a.name, url: a.url.to_s, description: '')
    end

    records = ResourceContent.translations.approved.where.not(name: nil).map do |r|
      ExportResourceRecord.new(
          id: r.id,
          resource_type: 'content',
          sub_type: 'translation',
          cardinality_type: r.cardinality_type,
          name: r.name,
          language_id: r.language_id,
          author_id: r.author_id.to_s,
          is_approved: r.approved?,
          priority: r.priority,
          author_name: r.author_name,
          language_name: r.language_name
      )
    end
    ExportResourceRecord.import(records, validate: false)

    Recitation.approved.each do |r|
      ExportRecitationRecord.create(id: r.id, reciter_name: r.reciter_name, style: r.style.to_s, is_approved: r.approved?)
    end

    records = Chapter.order('chapter_number asc').map do |c|
      ExportSurahRecord.new(id: c.id, name_simple: c.name_simple, name_arabic: c.name_arabic, surah_number: c.chapter_number, ayah_count: c.verses_count, revelation_place: c.revelation_place, revelation_order: c.revelation_order, bismillah_pre: c.bismillah_pre, name_complex: c.name_complex, pages: c.pages.to_s)
    end
    ExportSurahRecord.import(records, validate: false)

    puts 'exporting verses'
    records = Verse.order('verse_index asc').map do |v|
      ExportVerseRecord.new(id: v.id, uthmani_text: v.text_uthmani, imlaei_text: v.text_imlaei, uthmani_tajweed_text: v.text_uthmani_tajweed, indopak_text: v.text_indopak, uthmai_simple_text: v.text_uthmani_simple, imlaei_simple_text: v.text_imlaei_simple, ayah_key: v.verse_key, ayah_number: v.verse_number, page_number: v.page_number, juz_number: v.juz_number, hizb_number: v.hizb_number, rub_number: v.rub_number, surah_id: v.chapter_id, sajdaa_number: v.sajdah_number)
    end
    ExportVerseRecord.import(records, validate: false)

    puts 'exporting audio'
    records = AudioFile.where(recitation_id: Recitation.approved.pluck(:id)).map do |a|
      ExportAudioFileRecord.new(url: a.url, duration: a.duration.to_i, segments: a.segments.to_json, format: a.format.presence || 'mp3', recitation_id: a.recitation_id, ayah_id: a.verse_id)
    end
    ExportAudioFileRecord.import(records, validate: false)

    puts 'exporting words'
    Word.order('verse_id asc, position asc').includes(:arabic_transliteration).find_in_batches do |batch|
      records = batch.map do |w|
        ExportWordRecord.new(id: w.id,
                             uthmani_text: w.text_uthmani.to_s,
                             imlaei_text: w.text_imlaei.to_s,
                             indopak_text: w.text_indopak.to_s,
                             uthmani_simple_text: w.text_uthmani_simple.to_s,
                             imlaei_simple_text: w.text_imlaei_simple.to_s,
                             code_v1: w.code.to_s,
                             code_v2: w.code_v3.to_s,
                             line_number: w.line_number,
                             audio_path: w.audio_url.to_s,
                             surah_id: w.chapter_id,
                             ayah_id: w.verse_id,
                             char_type_id: w.char_type_id,
                             char_type_name: w.char_type_name,
                             position: w.position,
                             tr_continuous: !!w.arabic_transliteration&.continuous?,
                             ur_transliteration: w.arabic_transliteration&.text
        )
      end

      ExportWordRecord.import(records, validate: false)
    end

    puts 'exporting translations'
    Translation.where(resource_content_id: approved_translations).find_in_batches do |translations|
      records = translations.map do |t|
        ExportTranslationRecord.new(
            id: t.id,
            ayah_id: t.verse_id,
            resource_id: t.resource_content_id,
            language_id: t.language_id,
            resource_name: t.resource_name,
            language_name: t.language_name,
            text: t.text
        )
      end
      ExportTranslationRecord.import(records, validate: false)
    end

    records = FootNote.where(translation_id: Translation.select(:id).where(resource_content_id: approved_translations)).map do |f|
      ExportFootNoteRecord.new(
          id: f.id,
          translation_id: f.translation_id,
          language_id: f.language_id,
          language_name: f.language_name,
          text: f.text
      )
    end
    ExportFootNoteRecord.import(records, validate: false)

    # Export wbw translation resource content
    ResourceContent.translations.one_word.each do |r|
      ExportResourceRecord.where(
          id: r.id,
          resource_type: 'content',
          sub_type: 'translation',
          cardinality_type: r.cardinality_type,
          name: r.name,
          language_id: r.language_id,
          author_id: r.author_id.to_s,
          is_approved: r.approved?,
          priority: r.priority,
          language_name: r.language_name
      ).first_or_create
    end

    puts 'exporting words'
    records = WordTranslation.order('word_id asc').map do |t|
      ExportWordTranslationRecord.new(
          id: t.id,
          word_id: t.word_id,
          resource_id: t.resource_content_id,
          language_id: t.language_id,
          text: t.text.to_s,
          priority: t.priority
      )
    end
    ExportWordTranslationRecord.import(records, validate: false)

    puts 'exporting transliteration'
    records = Transliteration.where(language: Language.find_by_iso_code('en'), resource_type: 'Verse').order('resource_id ASC').map do |t|
      ExportTransliterationRecord.new(
          id: t.id,
          ayah_id: t.resource_id,
          language_id: t.language_id,
          text: t.text,
          created_at: t.created_at
      )
    end

    ExportTransliterationRecord.import(records, validate: false)

    puts 'exporting word transliteration'
    records = Transliteration.where(resource_type: 'Word').order('resource_id ASC').map do |t|
      ExportWordTransliterationRecord.new(
          id: t.id,
          word_id: t.resource_id,
          language_id: t.language_id,
          text: t.text,
          resource_id: t.resource_content_id
      )
    end
    ExportWordTransliterationRecord.import(records, validate: false)

    puts 'exporting urdu transliteration'
    #records = ArabicTransliteration.all.map do |t|
    # ExportUrduTransliterationRecord.new(
    #    id: t.id,
    #    word_id: t.word_id,
    #    text: t.text,
    #    is_continuous: t.continuous?
    # )
    # end
    #ExportUrduTransliterationRecord.import(records, validate: false)
  end
end