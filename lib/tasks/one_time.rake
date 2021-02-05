namespace :one_time do
  task convert_uzbek_cyrillic_to_latin: :environment do
    #
    # Convert "Muhammad Sodik Muhammad" Ubzek translation to latin
    #
    PaperTrail.enabled = false
    Translation.where(resource_content_id: 127).each do |translation|
      converter = Utils::CyrillicToLatin.new(translation.text)

      tr = Translation.where(resource_content_id: 55, verse_key: translation.verse_key).first
      tr.update_column(:text, converter.to_latin)

      tr.foot_notes.each do|foot_note|
        converter = Utils::CyrillicToLatin.new(foot_note.text)
        foot_note.update_column(:text, converter.to_latin)
      end
    end
  end

  task prepar_ayah_codes: :environment do
    PaperTrail.enabled = false

    Word.find_each do |word|
      word.update_column :code_v1, word.code_hex.hex.chr
    end

    Verse.unscoped.order("verse_index asc").each do |v|
      v1_codes = v.words.order("position asc").map do |word|
        word.code_hex.hex.chr
      end

      v2_codes = v.words.order("position asc").map do |word|
        word.code_v2
      end

      v.update(code_v1: v1_codes.join(' '), code_v2: v2_codes.join(' '))
    end
  end

  task import_missing_translations: :environment do
    PaperTrail.enabled = false

    mappings = [
        {
            language: Language.where(name: 'Amazigh').first_or_create,
            file: 'ber.mensur.txt',
            author: "Ramdane At Mansour",
            name: "Ramdane At Mansour"
        }, {
            language: Language.find_by_name('Bulgarian'),
            file: "bg.theophanov.txt",
            author: "Tzvetan Theophanov",
            name: "Tzvetan Theophanov",
            native: "Теофанов"
        }, {
            language: Language.find_by_name("Sindhi"),
            file: "sd.amroti.txt",
            author: "Taj Mehmood Amroti",
            name: "Taj Mehmood Amroti",
            native: "امروٽي"
        }, {
            resource: 44,
            language: Language.find_by_name("Romanian"),
            file: "ro.grigore.txt",
            author: "George Grigore",
            name: "Grigore",
            native: "Grigore"
        }
    ]

    data_source = DataSource.find_by(name: "Tanzil Project")
    mappings.each do |mapping|
      resource = mapping[:resource] ? ResourceContent.find(mapping[:resource]) : ResourceContent.new
      language = mapping[:language]
      author = Author.where(name: mapping[:author]).first_or_create

      resource.name = mapping[:name]
      resource.language = language
      resource.language_name = language.name
      resource.author = author
      resource.author_name = author.name
      resource.data_source = data_source
      resource.resource_type = 'content'
      resource.sub_type = 'translation'
      resource.cardinality_type = '1_ayah'
      resource.priority = resource.priority || 90
      resource.save

      if mapping[:native]
        resource.translated_names.where(language: language).first_or_create(name: mapping[:native])
      end

      translations = open("translations/#{mapping[:file]}").lines.to_a

      translations.each_with_index do |text, i|
        verse = Verse.find_by_verse_index(i + 1)
        translation = verse.translations.where(resource_content: resource).first_or_initialize
        translation.text = text.strip
        translation.language = language
        translation.language_name = language.name.downcase
        translation.resource_name = resource.name
        translation.priority = resource.priority
        translation.verse_key = verse.verse_key
        translation.chapter_id = verse.chapter_id
        translation.verse_number = verse.verse_number
        translation.juz_number = verse.juz_number
        translation.hizb_number = verse.hizb_number
        translation.rub_number = verse.rub_number
        translation.page_number = verse.page_number

        translation.save
      end
    end
  end

  task add_first_and_last_ayah_of_juz: :environment do
    require './lib/utils/quran'

    Juz.find_each do |juz|
      surah = juz.verse_mapping.keys.map(&:to_i)
      min, max = surah.min.to_s, surah.max.to_s

      verse_start = [min, juz.verse_mapping[min].split('-').first].join(':')
      verse_end = [max, juz.verse_mapping[max].split('-').last].join(':')

      first_ayah_of_juz = Utils::Quran.get_ayah_id_from_key(verse_start)
      last_ayah_of_juz = Utils::Quran.get_ayah_id_from_key(verse_end)
      verses_count = Verse.where('verse_index >= ? AND verse_index <= ?', first_ayah_of_juz, last_ayah_of_juz).size
      juz.update_columns(verses_count: verses_count, first_verse_id: first_ayah_of_juz, last_verse_id: last_ayah_of_juz)
    end
  end

  task add_verse_info_in_related_resources: :environment do
    Verse.find_each do |v|
      Translation.where(verse_id: v.id).update_all(chapter_id: v.chapter_id, verse_number: v.verse_number, verse_key: v.verse_key, juz_number: v.juz_number, hizb_number: v.hizb_number, rub_number: v.rub_number, page_number: v.page_number)
      AudioFile.where(verse_id: v.id).update_all(chapter_id: v.chapter_id, verse_number: v.verse_number, verse_key: v.verse_key, juz_number: v.juz_number, hizb_number: v.hizb_number, rub_number: v.rub_number, page_number: v.page_number)
      Tafsir.where(verse_id: v.id).update_all(chapter_id: v.chapter_id, verse_number: v.verse_number, verse_key: v.verse_key, juz_number: v.juz_number, hizb_number: v.hizb_number, rub_number: v.rub_number, page_number: v.page_number)
    end
  end

  task import_dutch_abdulasal: :environment do
    PaperTrail.enabled = false
    language = Language.find_by_iso_code 'nl'
    author = Author.where(name: 'Abdul Islam').first_or_create
    data_source = DataSource.where(name: 'Quran.com').first_or_create

    resource = ResourceContent.where(
        author_id: author.id,
        author_name: author.name,
        resource_type: "content",
        data_source: data_source,
        sub_type: ResourceContent::SubType::Translation,
        name: author.name,
        cardinality_type: "1_ayah",
        language_id: language.id,
        language_name: language.name.downcase,
        slug: "nl-abdalsalaam",
        priority: 50).first_or_initialize

    resource.save validate: false

    class TrAyah < ActiveRecord::Base
      self.table_name = "verses"
    end

    TrAyah.establish_connection({
                                    adapter: 'sqlite3',
                                    database: "#{Rails.root}/nl_abdalsalaam.db"}
    )

    TrAyah.all.each do |v|
      verse = Verse.find_by_verse_key("#{v.sura}:#{v.ayah}")

      translation = verse.translations.where(resource_content: resource).first_or_initialize
      translation.text = v.text.strip
      translation.language = language
      translation.language_name = language.name.downcase
      translation.resource_name = resource.name
      translation.priority = resource.priority
      translation.save
    end
  end

  task ur_jalendhari: :environment do
    PaperTrail.enabled = false

    language = Language.find_by_iso_code 'ur'
    author = Author.where(name: 'Fatah Muhammad Jalandhari').first_or_create
    data_source = DataSource.where(name: 'http://qurandatabase.org/').first_or_create

    resource = ResourceContent.where(
        author_id: author.id,
        author_name: author.name,
        resource_type: "content",
        data_source: data_source,
        sub_type: ResourceContent::SubType::Translation,
        name: "Fatah Muhammad Jalandhari",
        cardinality_type: "1_ayah",
        language_id: language.id,
        language_name: language.name.downcase,
        slug: "ur-fatah-muhammad-jalandhari",
        priority: 4).first_or_initialize

    resource.save validate: false
    lines = open("https://gist.githubusercontent.com/naveed-ahmad/2b49c921085838cb2cbc3b2ef95c53ed/raw/cf97c045df4823f18d6ba60da5d0ca04fe7ebb2d/ur-jalendhari.txt").lines
    lines = lines.to_a

    lines.each_with_index do |line, i|
      verse = Verse.find_by_verse_index(i + 1)
      translation = verse.translations.where(resource_content: resource).first_or_initialize
      translation.text = line.strip
      translation.language = language
      translation.language_name = language.name.downcase
      translation.resource_name = resource.name
      translation.priority = resource.priority
      translation.save
    end
  end

  task fix_tafheem_format: :environment do
    Translation.where(resource_content_id: 97).each do |t|
      t.foot_notes.each do |foot_note|
        text = foot_note.text

        text = text.split("\\n").map do |part|
          "<p>#{part}</p>"
        end
        foot_note.update_column :text, text.join(' ')
      end
    end
  end

  task fix_it_names: :environment do

    names = open("https://gist.githubusercontent.com/naveed-ahmad/93bbb1fe6e087cce9ba001e786868b19/raw/a2de9c790f5a976cb8d50d4d611d2600152d04fc/names.txt").lines
    names = names.to_a

    language = Language.find_by(iso_code: 'it')
    names.each_with_index do |name, i|
      chapter = Chapter.find_by_chapter_number(i + 1)
      tr = chapter.translated_names.where(language: language).first_or_initialize
      tr.name = name.strip
      tr.save
    end

    Chapter.order("chapter_number ASC").each do |c|
      name = names[c.chapter_number - 1].force_encoding("ISO-8859-5")
      tr = c.translated_names.where(language: language).first_or_initialize
      tr.name = name.strip
      tr.save
    end
  end

  task export_bridges: :environment do
    def fix_bridges_formatting(text, type)
      docs = Nokogiri::HTML::DocumentFragment.parse(text.gsub(/\u00A0/, ''))

      # Move footnote number inside higlighted word
      docs.search("span.h").each do |highlight|
        if footnote = highlight.next
          if 'a' == footnote.name && 'f' == footnote.attr('class')
            highlight.inner_html = "#{highlight.text}#{footnote.to_s} "
            footnote.remove
          end
        end
      end

      if 'footnote' == type
        docs.search('span.h').each do |highlight|
          unless highlight.text.ends_with?(' ')
            highlight.inner_html = "#{highlight.text} "
          end
        end
      end

      docs.search('i.s').each do |highlight|
        unless highlight.text.ends_with?(' ')
          highlight.inner_html = "#{highlight.text} "
        end
      end

      docs.search('sup').each do |sup|
        if sup.content.gsub(/\u00A0/, '').blank?
          sup.remove
        end
      end

      docs.to_s
    end

    def fix_bridges_formatting_2(text)
      docs = Nokogiri::HTML::DocumentFragment.parse(text)

      docs.search('i.s').each do |i|
        # remove space before
        text_node = i.previous
        if text_node.to_s.ends_with?(' ')
          text_node.content = text_node.to_s.chop
        end
      end

      docs.to_s
    end

    def remove_footnote_wrapper_link(text)
      docs = Nokogiri::HTML::DocumentFragment.parse(text)

      docs.search('a.f').each do |link|
        footnote = link.children.to_s
        link.replace(footnote)
      end

      docs.to_s
    end

    Translation.where(resource_content_id: 149).find_each do |t|
      t.update_column :text, fix_bridges_formatting(t.text, 'tr')

      FootNote.where(translation_id: t.id).each do |f|
        f.update_column :text, fix_bridges_formatting(f.text, 'footnote')
      end
    end

    Translation.where(resource_content_id: 149).find_each do |t|
      t.update_column :text, fix_bridges_formatting_2(t.text)

      FootNote.where(translation_id: t.id).each do |f|
        f.update_column :text, fix_bridges_formatting_2(f.text)
      end
    end

    Translation.where(resource_content_id: 149).find_each do |t|
      t.update_column :text, remove_footnote_wrapper_link(t.text)
    end
  end

  task import_ru_saddi: :environment do
    language = Language.find_by_iso_code 'ru'
    author = Author.find(112)

    resource = ResourceContent.where(
        author_id: author.id,
        author_name: author.name,
        resource_type: "content",
        sub_type: "tafsir",
        name: "Russian Tafseer Al Saddi",
        cardinality_type: "1_ayah",
        language_id: language.id,
        language_name: language.name.downcase,
        slug: "ru-tafseer-al-saddi",
        priority: 5).first_or_initialize

    resource.save validate: false

    data = JSON.parse File.read("tafsir.json")
    data.each do |t|
      surah = t['sura']
      ayah = t['ayah']

      verse = Verse.find_by_verse_key("#{surah}:#{ayah}")

      tafsir = Tafsir.where(
          verse_id: verse.id,
          language_id: language.id,
          resource_content_id: resource.id,
      ).first_or_initialize

      tafsir.text = t['tafsir']
      tafsir.save
    end
  end

  task import_bengli_translations: :environment do
    PaperTrail.enabled = false
    language = Language.find_by_iso_code 'bn'

    resource = ResourceContent.where(
        author_id: author.id,
        data_source_id: data_source.id,
        author_name: author.name,
        resource_type: "content",
        sub_type: "tafsir",
        name: names[:name],
        cardinality_type: "1_ayah",
        language_id: language.id,
        language_name: "bengali",
        slug: "bn-#{names[:name].downcase.gsub(/\s+/, '-')}",
        priority: 5).first_or_create


    BnTafsir.all.each do |t|
      verse = Verse.find_by_verse_key("#{t.sura}:#{t.ayah}")
      tafsir = Tafsir.where(
          verse_id: verse.id,
          language_id: language.id,
          resource_content_id: resource.id,
      ).first_or_initialize

      mapping = {
          bn_taisirul: {
              name: 'Taisirul Quran',
              author: 'Tawheed Publication'
          },
          bn_bayaan: {
              name: 'Rawai Al-bayan',
              author: 'Bayaan Foundation'
          },
          bn_mujibur: {
              name: 'Sheikh Mujibur Rahman',
              author: 'Darussalaam Publication'
          }
      }

      tafisr_mapping = {
          bn_tafsir_kathir: {
              name: 'তাফসির ইবনে কাছের রহ',
              author: 'Tawheed Publication',
              slug: 'bn-tafseer-ibn-e-kaseer'
          },
          bn_tafsirbayaan: {
              name: 'Tafsir Ahsanul Bayaan',
              author: 'Bayaan Foundation',
              slug: 'bn-tafseer-ahsanul-bayaan'
          },
          bn_tafsirzakaria: {
              name: 'Tafsir Abu Bakr Zakaria',
              author: 'King Fahd Quran Printing Complex',
              slug: 'bn-tafseer-abu-bakr-zakaria'
          }
      }

      class BnTranslation < ActiveRecord::Base
        self.table_name = "verses"
      end

      class BnTafsir < ActiveRecord::Base
        self.table_name = "verses"
      end

      tafisr_mapping.each do |key, names|
        BnTafsir.establish_connection(
            {adapter: 'sqlite3',
             database: "#{Rails.root}/data/bn/#{key}.db"
            })

        author = Author.where(name: names[:author]).first_or_create
        data_source = DataSource.where(name: 'Greentech Apps Foundation').first_or_create

        resource = ResourceContent.where(
            author_id: author.id,
            data_source_id: data_source.id,
            author_name: author.name,
            resource_type: "content",
            sub_type: "tafsir",
            name: names[:name],
            cardinality_type: "1_ayah",
            language_id: language.id,
            language_name: "bengali",
            slug: "bn-#{names[:name].downcase.gsub(/\s+/, '-')}",
            priority: 5).first_or_create


        BnTafsir.all.each do |t|
          verse = Verse.find_by_verse_key("#{t.sura}:#{t.ayah}")
          tafsir = Tafsir.where(
              verse_id: verse.id,
              language_id: language.id,
              resource_content_id: resource.id,
          ).first_or_initialize

          tafsir.text = t.text.strip
          tafsir.language_name = language.name.downcase
          tafsir.resource_name = resource.name
          tafsir.verse_key = verse.verse_key

          tafsir.save!
        end
      end

      mapping.each do |key, names|
        BnTranslation.establish_connection(
            {adapter: 'sqlite3',
             database: "#{Rails.root}/data/bn/#{key}.db"
            })

        author = Author.where(name: names[:author]).first_or_create
        data_source = DataSource.where(name: 'Greentech Apps Foundation').first_or_create

        resource = ResourceContent.where(
            author_id: author.id,
            data_source_id: data_source.id,
            author_name: author.name,
            resource_type: "content",
            sub_type: "translation",
            name: names[:name],
            cardinality_type: "1_ayah",
            language_id: language.id,
            language_name: "bengali",
            slug: "bn-#{names[:name].downcase.gsub(/\s+/, '-')}",
            priority: 5).first_or_create


        BnTranslation.all.each do |t|
          verse = Verse.find_by_verse_key("#{t.sura}:#{t.ayah}")
          translation = Translation.where(
              verse_id: verse.id,
              language_id: language.id,
              resource_content_id: resource.id,
          ).first_or_initialize

          translation.text = t.text.strip
          translation.language_name = language.name.downcase
          translation.resource_name = resource.name
          translation.priority = resource.priority

          translation.save!
        end
      end
    end
  end

  task export_csv_templates: :environment do
    CSV.open("translation-names.csv", "wb") do |csv|
      csv << ["ID", "Name", "Source language"] + Language.where('translations_count > 0').pluck(:name).uniq

      ResourceContent.translations.approved.each do |r|
        csv << [r.id, r.name, r.language.name]
      end
    end
  end

  task update_lang_translation_count: :environment do
    langs = Translation.pluck(:language_id).uniq

    langs.each do |lang|
      language = Language.find(lang)
      language.update translations_count: ResourceContent.translations.one_verse.where(language_id: lang).size
    end

    TranslatedName.where(language_priority: nil).update_all language_priority: 2
  end

  task export_qcf_codes: :environment do
    CSV.open("codes.csv", "wb") do |csv|
      csv << ["Ayah Key", "Codes"]
      Verse.unscoped.order("verse_index asc").each do |v|
        codes = v.words.order("position asc").map do |word|
          word.code_hex.hex.chr
        end

        csv << [v.verse_key, codes.join(' ')]
      end
    end
  end

  task export_codes_json: :environment do

    File.open("v1.json", "wb") do |file|
      json = {}

      Verse.unscoped.order("verse_index asc").each do |v|
        codes = v.words.order("position asc").map do |word|
          word.code_hex.hex.chr
        end

        json[v.verse_key] = {page: v.page_number,
                             text: codes.join(' '),
                             text_uthmani: v.text_uthmani
        }
      end

      file.puts json.to_json
    end

    File.open("en.json", "wb") do |file|
      json = {}

      Verse.unscoped.eager_load(:translations).where(translations: {resource_content_id: 131}).order("verse_index asc").each do |v|
        text = v.translations.first.text
        json[v.verse_key] = {text: text}
      end

      file.puts json.to_json
    end


    File.open("bn.json", "wb") do |file|
      json = {}

      Verse.unscoped.eager_load(:translations).where(translations: {resource_content_id: 167}).order("verse_index asc").each do |v|
        text = v.translations.first.text
        json[v.verse_key] = {text: text}
      end

      file.puts json.to_json
    end


    File.open("hi.json", "wb") do |file|
      json = {}

      Verse.unscoped.eager_load(:translations).where(translations: {resource_content_id: 122}).order("verse_index asc").each do |v|
        text = v.translations.first.text
        json[v.verse_key] = {text: text}
      end

      file.puts json.to_json
    end


    File.open("id.json", "wb") do |file|
      json = {}

      Verse.unscoped.eager_load(:translations).where(translations: {resource_content_id: 134}).order("verse_index asc").each do |v|
        text = v.translations.first.text
        json[v.verse_key] = {text: text}
      end

      file.puts json.to_json
    end

    File.open("en-bridges.json", "wb") do |file|
      json = {}

      Verse.unscoped.eager_load(:translations).where(translations: {resource_content_id: 149}).order("verse_index asc").each do |v|
        text = v.translations.first.text
        json[v.verse_key] = {text: text}
      end

      file.puts json.to_json
    end


    File.open("fr.json", "wb") do |file|
      json = {}

      Verse.unscoped.eager_load(:translations).where(translations: {resource_content_id: 136}).order("verse_index asc").each do |v|
        text = v.translations.first.text
        json[v.verse_key] = {text: text}
      end

      file.puts json.to_json
    end

    File.open("tr.json", "wb") do |file|
      json = {}

      Verse.unscoped.eager_load(:translations).where(translations: {resource_content_id: 77}).order("verse_index asc").each do |v|
        text = v.translations.first.text
        json[v.verse_key] = {text: text}
      end

      file.puts json.to_json
    end


    File.open("tajweed.json", "wb") do |file|
      json = {}

      Verse.unscoped.order("verse_index asc").each do |v|
        json[v.verse_key] = {page: v.page_number, text: "#{v.text_uthmani_tajweed}"}
      end

      file.puts json.to_json
    end


    File.open("ur.json", "wb") do |file|
      json = {}

      Verse.unscoped.eager_load(:translations).where(translations: {resource_content_id: 151}).order("verse_index asc").each do |v|
        text = v.translations.first.text
        json[v.verse_key] = {text: text}
      end

      file.puts json.to_json
    end

  end

  task fix_word_end_translation: :environment do
    arabic = Language.find_by_iso_code('ar')
    Chapter.find_each do |c|
      name = c.translated_names.where(language: arabic).first_or_create
      name.update(name: "سورة #{c.name_arabic}", language_name: 'arabic')
    end

    PaperTrail.enabled = false
    ActiveRecord::Base.logger = nil
    Word.where(char_type_name: 'end').each do |w|
      tr = WordTranslation.where(
          word: w,
          language_id: 174,
          resource_content_id: 104,
          priority: 1,
      ).first_or_create

      tr.text = "آیت  #{w.verse.verse_number}"
      tr.save


      tr = WordTranslation.where(
          word: w,
          language_id: 20,
          resource_content_id: 99,
          priority: 1,
      ).first_or_create

      tr.text = "শ্লোক #{w.verse.verse_number}"
      tr.save

      tr = WordTranslation.where(
          word: w,
          language_id: 67,
          resource_content_id: 100,
          priority: 1
      ).first_or_create

      tr.text = "Ayat #{w.verse.verse_number}"
      tr.save

      tr = WordTranslation.where(
          word: w,
          language_name: "english",
          language_id: 38,
          resource_content_id: 59,
          priority: 5
      ).first_or_create

      tr.text = "Ayah #{w.verse.verse_number}"
      tr.save
    end


    WordTranslation.where(language_id: 20).update_all priority: 1, language_name: 'bengali'
    WordTranslation.where(language_id: 174).update_all priority: 1, language_name: 'urdu'
    WordTranslation.where(language_id: 38).update_all priority: 5, language_name: 'english'
    WordTranslation.where(language_id: 67).update_all priority: 1, language_name: 'indonesian'

    def to_arabic(num)
      arabic = ["٠", "١", "٢", "٣", "٤", "٥", "٦", "٧", "٨", "٩"]

      digits = num.to_s.split("")
      digits.map do |n|
        arabic[n.to_i]
      end.join('')
    end

    Verse.find_each do |v|
      last_word = v.words.where(char_type_name: 'end').first

      text = to_arabic(v.verse_number)
      last_word.update_columns(
          text_indopak: text,
          text_uthmani: text,
          text_imlaei_simple: text,
          text_imlaei: text,
          text_uthmani_simple: text
      )
    end

    Verse.find_each do |v|
      num = to_arabic(v.verse_number)
      reverse = num.reverse

      text = v.text_uthmani_tajweed
      v.update_column :text_uthmani_tajweed, text.gsub(reverse, num)
    end

    #
    #Verse.find_each do |v|
    #  text = "<span class=end>#{to_arabic(v.verse_number)}</span>"
    #  tajweed = v.text_uthmani_tajweed.gsub(reg, '').strip
    #  v.update_column :text_uthmani_tajweed, "#{tajweed} #{text}"
    #end

    # 103 translation has issues, fix em!
    Translation.where("text like ?", "%</sup>>%").update_all("text = REPLACE(text, '</sup>>', '>')")

    reg = /\<sup(\s)+foot_note=(\d+)\<sup/
    foot_note_issues = []
    Translation.find_each do |t|
      if t.text.match(reg)
        foot_note_issues << t.id
      end
    end
  end

  task import_ibnekaseer_urdu: :environment do
    def split_paragraphs(text)
      return [] if text.blank?

      text.to_str.split(/\r\n?+/).select do |para|
        para.presence.present?
      end
    end

    def simple_format(text)
      paragraphs = split_paragraphs(text)
      paragraphs.map! { |paragraph|
        "<p>#{paragraph.strip.gsub(/\r\n?/, "<br />").gsub(/\n\n?+/, '')}</p>"
      }.join('').html_safe
    end

    PaperTrail.enabled = false
    ActiveRecord::Base.logger = nil


    urdu = Language.find_by(name: 'Urdu')
    data_source = DataSource.where(name: 'www.equranlibrary.com').first_or_create


    tafsir_resource_content = ResourceContent.where(
        name: 'تفسیر ابنِ کثیر',
        cardinality_type: ResourceContent::CardinalityType::OneVerse,
        resource_type: ResourceContent::ResourceType::Content,
        sub_type: ResourceContent::SubType::Tafsir,
        language: urdu,
        data_source: data_source,
        language_name: urdu.name.downcase,
        slug: 'tafseer-ibn-e-kaseer-urdu'
    ).first_or_create

    Tafsir.where(resource_content: tafsir_resource_content).delete_all

    Verse.unscoped.order('verse_index asc').each do |verse|
      url = "http://www.equranlibrary.com/tafseer/ibnekaseer/#{verse.verse_key.gsub(':', '/')}"

      response = with_rescue_retry([RestClient::Exceptions::ReadTimeout], retries: 3, raise_exception_on_limit: true) do
        RestClient.get(url)
      end

      if response && 200 == response.code
        docs = Nokogiri.parse(response.body)

        puts verse.verse_key
        tafsir_text = docs.search(".columns .translation")[2]&.text

        if tafsir_text.present?
          tafsir = Tafsir.where(verse_id: verse.id, resource_content_id: tafsir_resource_content.id).first_or_initialize
          tafsir.verse_key = verse.verse_key
          tafsir.language = urdu
          tafsir.language_name = urdu.name.downcase
          tafsir.resource_name = tafsir_resource_content.name
          tafsir.text = simple_format(tafsir_text.strip)
          tafsir.save
        end
      end
    end
  end

  task import_bayan_ul_quran: :environment do
    def split_paragraphs(text)
      return [] if text.blank?

      text.to_str.split(/\r\n?+/).select do |para|
        para.presence.present?
      end
    end

    def simple_format(text)
      paragraphs = split_paragraphs(text)
      paragraphs.map! { |paragraph|
        "<p>#{paragraph.strip.gsub(/\r\n?/, "<br />").gsub(/\n\n?+/, '')}</p>"
      }.join('').html_safe
    end

    PaperTrail.enabled = false
    ActiveRecord::Base.logger = nil

    translator_name = "ڈاکٹر اسرار احمد"

    urdu = Language.find_by(name: 'Urdu')
    data_source = DataSource.where(name: 'www.equranlibrary.com').first_or_create
    author = Author.where(name: "Dr. Israr Ahmad").first_or_create
    author.translated_names.where(language: urdu).first_or_create(language_name: urdu.name.downcase, name: translator_name)

    translation_resource_content = ResourceContent.where(
        name: "بیان القرآن",
        cardinality_type: ResourceContent::CardinalityType::OneVerse,
        resource_type: ResourceContent::ResourceType::Content,
        sub_type: ResourceContent::SubType::Translation,
        language: urdu,
        author: author,
        author_name: author.name,
        data_source: data_source,
        language_name: urdu.name.downcase,
        priority: 3,
        slug: 'bayan-ul-quran'
    ).first_or_create

    tafsir_resource_content = ResourceContent.where(
        name: 'تفسیر بیان القرآن',
        cardinality_type: ResourceContent::CardinalityType::OneVerse,
        resource_type: ResourceContent::ResourceType::Content,
        sub_type: ResourceContent::SubType::Tafsir,
        language: urdu,
        author: author,
        author_name: author.name,
        data_source: data_source,
        language_name: urdu.name.downcase,
        slug: 'tafsir-bayan-ul-quran'
    ).first_or_create

    Translation.where(resource_content: translation_resource_content).delete_all
    Tafsir.where(resource_content: tafsir_resource_content).delete_all

    Verse.unscoped.order('verse_index asc').each do |verse|
      url = "http://www.equranlibrary.com/tafseer/bayanulquran/#{verse.verse_key.gsub(':', '/')}"

      response = with_rescue_retry([RestClient::Exceptions::ReadTimeout], retries: 3, raise_exception_on_limit: true) do
        RestClient.get(url)
      end

      if response && 200 == response.code
        docs = Nokogiri.parse(response.body)

        puts verse.verse_key
        translation_text = docs.search(".columns .translation")[1].text
        tafsir_text = docs.search(".columns .translation")[2]&.text

        if tafsir_text.present?
          tafsir = Tafsir.where(verse_id: verse.id, resource_content_id: tafsir_resource_content.id).first_or_initialize
          tafsir.verse_key = verse.verse_key
          tafsir.language = urdu
          tafsir.language_name = urdu.name.downcase
          tafsir.resource_name = tafsir_resource_content.name
          tafsir.text = simple_format(tafsir_text.strip)
          tafsir.save
        end

        translation = verse.translations.where(resource_content: translation_resource_content).first_or_initialize
        translation.text = translation_text.strip
        translation.language = urdu
        translation.language_name = urdu.name.downcase
        translation.resource_name = translation_resource_content.name
        translation.priority = translation_resource_content.priority

        translation.save
      end
    end
  end

  task import_maarif_ul_quran: :environment do
    def split_paragraphs(text)
      return [] if text.blank?

      text.to_str.split(/\r\n?+/).select do |para|
        para.presence.present?
      end
    end

    def simple_format(text)
      paragraphs = split_paragraphs(text)
      paragraphs.map! { |paragraph|
        "<p>#{paragraph.strip.gsub(/\r\n?/, "<br />").gsub(/\n\n?+/, '<br/>')}</p>"
      }.join('').html_safe
    end

    PaperTrail.enabled = false

    tafsir_name = "Maarif-ul-Quran"
    translator_name = "Mufti Muhammad Shafi"

    language = Language.find_by(name: 'English')

    data_source = DataSource.where(name: 'www.equranlibrary.com').first_or_create
    author = Author.where(name: translator_name).first_or_create
    author.translated_names.where(language_id: 174).first_or_create(language_name: 'urdu', name: 'مفتی محمد شفیع')

    translation_resource_content = ResourceContent.where(
        name: tafsir_name,
        cardinality_type: ResourceContent::CardinalityType::OneVerse,
        resource_type: ResourceContent::ResourceType::Content,
        sub_type: ResourceContent::SubType::Translation,
        language: language,
        author: author,
        author_name: author.name,
        data_source: data_source,
        language_name: 'english',
        priority: 3,
        slug: 'en-maarif-ul-quran'
    ).first_or_create

    tafsir_resource_content = ResourceContent.where(
        cardinality_type: ResourceContent::CardinalityType::OneVerse,
        resource_type: ResourceContent::ResourceType::Content,
        sub_type: ResourceContent::SubType::Tafsir,
        language: language,
        author: author,
        author_name: author.name,
        data_source: data_source,
        language_name: 'english',
        slug: 'en-maarif-ul-quran'
    ).first_or_create

    Translation.where(resource_content: translation_resource_content).delete_all
    Tafsir.where(resource_content: tafsir_resource_content).delete_all

    Verse.unscoped.order('verse_index asc').each do |verse|
      url = "http://www.equranlibrary.com/tafseer/maarifulquranenglish/#{verse.verse_key.gsub(':', '/')}"

      response = with_rescue_retry([RestClient::Exceptions::ReadTimeout], retries: 3, raise_exception_on_limit: true) do
        RestClient.get(url)
      end

      if response && 200 == response.code
        docs = Nokogiri.parse(response.body)

        puts verse.verse_key
        translation_text = docs.search(".translation-english")[0].text.to_s.gsub(/\r\n/, ' ').strip
        tafsir_text = docs.search(".translation-english .preformatted")[1]

        if tafsir_text.present?
          tafsir_text = tafsir_text.children.first.to_s

          tafsir = Tafsir.where(verse_id: verse.id, resource_content_id: tafsir_resource_content.id).first_or_initialize
          tafsir.language = language
          tafsir.language_name = 'english'
          tafsir.resource_name = tafsir_name
          tafsir.text = simple_format(tafsir_text.strip)
          tafsir.save
        end

        translation = verse.translations.where(resource_content: translation_resource_content).first_or_initialize
        translation.resource_name = tafsir_name
        translation.text = translation_text.strip
        translation.language = language
        translation.language_name = 'english'
        translation.resource_name = tafsir_name
        translation.priority = translation_resource_content.priority

        translation.save
      end
    end
  end

  task import_fizilalalquran: :environment do
    def split_paragraphs(text)
      return [] if text.blank?

      text.to_str.split(/\r\n?+/).select do |para|
        para.presence.present?
      end
    end

    def simple_format(text)
      paragraphs = split_paragraphs(text)
      paragraphs.map! { |paragraph|
        "<p>#{paragraph.strip.gsub(/\r\n?/, "<br />").gsub(/\n\n?+/, '<br/>')}</p>"
      }.join('').html_safe
    end

    PaperTrail.enabled = false
    ActiveRecord::Base.logger = nil

    tafsir_name = "فی ظلال القرآن"
    translator_name = "سید قطب"

    urdu = Language.find_by(name: 'Urdu')
    data_source = DataSource.where(name: 'www.equranlibrary.com').first_or_create
    author = Author.where(name: "Sayyid Ibrahim Qutb").first_or_create
    author.translated_names.where(language: urdu).first_or_create(language_name: urdu.name.downcase, name: translator_name)

    translation_resource_content = ResourceContent.where(
        name: tafsir_name,
        cardinality_type: ResourceContent::CardinalityType::OneVerse,
        resource_type: ResourceContent::ResourceType::Content,
        sub_type: ResourceContent::SubType::Translation,
        language: urdu,
        author: author,
        author_name: author.name,
        data_source: data_source,
        language_name: urdu.name.downcase,
        priority: 3,
        slug: 'urdu-sayyid-qatab'
    ).first_or_create

    tafsir_resource_content = ResourceContent.where(
        cardinality_type: ResourceContent::CardinalityType::OneVerse,
        resource_type: ResourceContent::ResourceType::Content,
        sub_type: ResourceContent::SubType::Tafsir,
        language: urdu,
        author: author,
        author_name: author.name,
        data_source: data_source,
        language_name: urdu.name.downcase,
        slug: 'urdu-sayyid-qatab'
    ).first_or_create

    Translation.where(resource_content: translation_resource_content).delete_all
    Tafsir.where(resource_content: tafsir_resource_content).delete_all

    Verse.unscoped.order('verse_index asc').each do |verse|
      url = "http://www.equranlibrary.com/tafseer/fizilalalquran/#{verse.verse_key.gsub(':', '/')}"

      response = with_rescue_retry([RestClient::Exceptions::ReadTimeout], retries: 3, raise_exception_on_limit: true) do
        RestClient.get(url)
      end

      if response && 200 == response.code
        docs = Nokogiri.parse(response.body)

        puts verse.verse_key
        translation_text = docs.search(".columns .translation")[1].text
        tafsir_text = docs.search(".columns .translation")[2]&.text

        if tafsir_text.present?
          tafsir = Tafsir.where(verse_id: verse.id, resource_content_id: tafsir_resource_content.id).first_or_initialize
          tafsir.language = urdu
          tafsir.language_name = urdu.name.downcase
          tafsir.resource_name = tafsir_name
          tafsir.text = simple_format(tafsir_text.strip)
          tafsir.save
        end

        translation = verse.translations.where(resource_content: translation_resource_content).first_or_initialize
        translation.resource_name = tafsir_name
        translation.text = translation_text.strip
        translation.language = urdu
        translation.language_name = urdu.name.downcase
        translation.resource_name = tafsir_name
        translation.priority = translation_resource_content.priority

        translation.save

        if verse.id > 10
          sdsds
        end
      end
    end
  end

  task import_tafheem: :environment do
    PaperTrail.enabled = false
    ActiveRecord::Base.logger = nil

    split_reg = /\d+[^()]+/

    # tafheemulquran urdu
    resource_content = ResourceContent.find(97)
    foot_note_resource_content = ResourceContent.find(98)
    language = resource_content.language

    Translation.where(resource_content: resource_content).delete_all
    FootNote.where(resource_content: foot_note_resource_content).delete_all

    Verse.unscoped.order('verse_index asc').each do |verse|
      url = "http://www.equranlibrary.com/tafseer/tafheemulquran/#{verse.verse_key.gsub(':', '/')}"

      translation = verse.translations.where(resource_content: resource_content, language: language).first_or_initialize

      response = with_rescue_retry([RestClient::Exceptions::ReadTimeout], retries: 3, raise_exception_on_limit: true) do
        RestClient.get(url)
      end

      if response && 200 == response.code
        docs = Nokogiri.parse(response.body)

        puts verse.verse_key
        translation.save validate: false

        translation_text = docs.search(".columns .translation")[1].text
        footnotes = docs.search(".columns .translation")[2]&.text

        if footnotes.present?
          first = footnotes.scan(/\d+/).first
          footnotes_numbers = translation_text.scan(/\d+/)

          _skip, foot_notes_text = footnotes.split(Regexp.new("#{first}[^()]"))
          foot_notes_texts = foot_notes_text.to_s.split(/\d+[^()]/)

          foot_notes_texts = foot_notes_texts.map do |s|
            parts = s.to_s.split("\n")
            parts.pop
            parts.join('\n')
          end

          foot_note_index = 0

          footnotes_numbers.each_with_index do |num, i|
            footnote_text = foot_notes_texts[i]

            if footnote_text.present?
              footnote = translation.foot_notes.create(text: footnote_text.to_s.strip, language: language, language_name: language.name.downcase, resource_content: foot_note_resource_content)

              translation_text = translation_text.gsub("#{num}", "<sup foot_note=#{footnote.id}>#{foot_note_index += 1}</sup>")
            end
          end
        end

        translation.text = translation_text.strip
        translation.language = language
        translation.language_name = language.name.downcase
        translation.resource_name = resource_content.name
        translation.priority = resource_content.priority

        translation.save
      end
    end
  end

  task fix_indopak_wbw: :environment do
    PaperTrail.enabled = false
    issues = []

    WbwText.find_each do |t|
      word = t.word
      if word.char_type_name != 'end'
        begin
          word.update_columns(text_indopak: t.text_indopak.to_s.strip, text_uthmani: t.text_uthmani.to_s.strip, text_imlaei: t.text_imlaei.to_s.strip)
        rescue Exception => e
          issues << t.id
        end
      end
    end

    BackupJob.perform_now("updated-wbw")
  end

  task prepare_wbw_text: :environment do
    Word.unscoped.order('verse_id asc').each do |w|
      WbwText.where(word_id: w.id).first_or_create({
                                                       verse_id: w.verse_id,
                                                       text_indopak: w.text_indopak,
                                                       text_uthmani: w.text_madani,
                                                       text_imlaei: w.text_imlaei
                                                   })
    end

    Verse.find_each do |v|
      uthmani_words = v.text_madani.split(/\s+/)
      pause_index = 0

      v.words.order('position asc').each_with_index do |w, i|
        if w.char_type_name == 'pause'
          text = ''
          pause_index = 0
        else
          text = uthmani_words[i + pause_index]
        end

        WbwText.where(word_id: w.id).update(text_uthmani: text)
      end
    end
  end

  task import_madani_text: :environment do
    module Kernel
      def with_rescue_retry(exceptions, on_exception: nil, retries: 5, raise_exception_on_limit: true)
        try = 0

        begin
          yield try
        rescue *exceptions => exc
          on_exception.call(exc) if on_exception
          sleep 2
          try += 1
          try <= retries ? retry : raise_exception_on_limit && raise
        end
      end
    end


    url = "http://tanzil.net/tanzil/php/get-aya.php"
    require 'rest-client'

    start = 0
    verse_index = 1
    while (start < 6236) do
      response = with_rescue_retry([RestClient::Exceptions::ReadTimeout], retries: 3, raise_exception_on_limit: true) do
        RestClient.post(url, {type: 'uthmani', transType: 'en.itani', pageNum: 1, startAya: start, endAya: start + 10, version: 1.5}, {accept: 'application/json', Referer: 'http://tanzil.net/', Origin: 'http://tanzil.net'})
      end

      verses = JSON.parse(response.body)['quran']
      verses = verses.is_a?(Array) ? verses : verses.values

      verses.each do |line|
        text = line.strip
        puts text
        Verse.find_by_verse_index(verse_index).update_column(:text_madani, text)
        verse_index += 1
      end
      start = start + 10
    end
  end

  task import_75: :environment do
    Translation.where("text like ?", "%<sup foot_note%").pluck(:resource_content_id).uniq.map do |resource_id|
      resource = ResourceContent.find(resource_id)
      if resource.approved?
        file_name = "#{resource.language_name}-#{resource.name}".underscore.gsub(/\s/, '_')
        ExportTranslationWithFootNoteJob.new.perform(resource_id, file_name)
      end
    end

    file = "https://docs.google.com/spreadsheets/d/e/2PACX-1vT2IDGm8MOTsJVZ5tQAXrx289xVvvCpj6T7DHbZ9ZEyWfGHcvlCWhUe4WzfaZZXEevxAkHI50GdBIlj/pub?output=csv"
    resource_content = ResourceContent.find(75)

    content = open(file).read

    CSV.parse(content).each do |row|
      verse = Verse.find_by_verse_key("#{row[0]}:#{row[1]}")

      verse.translations.find_by(resource_content_id: resource_content.id).update(text: row[2])
    end
  end

  task prepare_uthmani_simple: :environment do
    codes = {}
    ResourceContent.translations.one_verse.each do |r|
      language = r.language
      text = Translation.where(resource_content: r).first.text
      codes[language.id] ||= []
      codes[language.id] << CLD.detect_language(text)[:code].to_s.split('-').first
    end

    AudioFile.where("url ilike ?", "//%").count

    AudioFile.where("url ilike ?", "verses/%").count
    AudioFile.where("url ilike ?", "verses/%").update_all("url = REPLACE(url, 'verses/', '')")

    files = AudioFile.where("url ilike ?", "%//quranicaudio/%").size

    AudioFile.update_all("url = REPLACE(url, '//mirrors.quranicaudio.com/everyayah/Abdul_Basit_Murattal_64kbps/', 'AbdulBaset/Murattal/mp3')")


    files = AudioFile.where("url ilike ?", "AbdulBaset/Murattal%")

    files.update_all("url = REPLACE(url, 'AbdulBaset/Murattal/', 'AbdulBaset/Murattal/mp3/')")


    update_all("url = REPLACE(url, 'verses/', '')")

    Word.where("audio_url ilike ?", "verses/%").update_all("audio_url = REPLACE(audio_url, 'verses/', '')")


    p = UpdatedPost.where("content ilike ?", "%strength.runnersconnect.net/dev/wp-content/uploads/2014/06/%")
    p.update_all("content = REPLACE(content, 'strength.runnersconnect.net/dev/wp-content/uploads/2014/06/', 'cdn-strength-training.runnersconnect.net/Images/')")


    codes.each do |id, indexes|
      indexes = indexes.compact.uniq

      language = Language.find(id)
      indexes.each do |code|
        if code != language.iso_code
          lang = Language.find_by_iso_code(code)
          lang.es_indexes << language.iso_code
          lang.save
        end
      end
    end

    ResourceContent.update_all(priority: 5)
    # Clear Quran
    ResourceContent.find(131).update(priority: 1)
    # Bridge
    ResourceContent.find(149).update(priority: 2)

    ResourceContent.where(language_name: 'urdu').update(priority: 3)

    ResourceContent.find_each do |r|
      Translation.where(resource_content: r.id).update_all priority: r.priority
    end

    Verse.find_each do |v|
      simple = v.text_madani.gsub(/\u06E6|\ufe80|\u06E5|\u064B|\u0670|\u0FBCx|\u0FB5x|\u0FBB6|\u0FE7x|\u0FC62|\u0FC61|\u0FC60|\u0FDF0|\u0FDF1|\u0066D|\u0061F|\u060F|\u060E|\u060D|\060C|\u060B|\u064C|\u064D|\u064E|\u064F|\u0650|\u0651|\u0652|\u0653|\u0654|\u0655|\u0656|\0657|\u0658/, '')

      # "ٱ|إ|أ" => ا
      simple = simple.gsub(/\u0671|\u0625|\u0623/, "\u0627".encode('utf-8'))

      # الله => الله
      simple = simple.gsub(/\u0627\u0644\u0644\u0647/, "\u0627\u0644\u0644\u0647".encode('utf-8'))

      v.update_column :text_uthmani_simple, simple.gsub(/\u0671|\u0625|\u0623/, "\u0627".encode('utf-8'))
    end
  end

  task prepare_font_v2_codes_new: :environment do
    PaperTrail.enabled = false

    content = File.open("data/v2-codes/v2_codes.txt").read
    pages = JSON.parse(content)

    1.upto(604).each do |p|
      File.open("data/v2-pages/#{p}.html", "wb") do |file|
        file.puts "<div>#{pages[p.to_s]}</div>"
      end
    end

    code = page_534[word_index].unpack("U*")[0]

    word.code_hex_v3 = code.to_s(16)

  end

  task prepare_font_v2_codes: :environment do
    page_576 = "ﭑﭒﭓﭔﭕﭖﭗﭘﭙﭚﭛﭜﭝﭞﭟﭠﭡﭢﭣﭤﭥﭦﭧﭨﭩﭪﭫﭬﭭﭮﭯﭰﭱﭲﭳﭴﭵﭶﭷﭸﭹﭺﭻﭼﭽﭾﭿﮀﮁﮂﮃﮄﮅﮆﮇﮈﮉﮊﮋﮌﮍﮎﮏﮐﮑﮒﮓﮔﮕﮖﮗﮘﮙﮚﮛﮜﮝﮞﮟﮠﮡﮢﮣﮤﮥﮦﮧﮨﮩﮪﮫﮬﮭﮮﮯﮰﮱﯓﯔﯕﯖﯗﯘﯙﯚﯛﯜﯝﯞﯟﯠﯡﯢﯣﯤﯥﯦﯧﯨﯩﯪﯫﯬﯭﯮﯯﯰﯱﯲﯳﯴﯵﯶﯷﯸﯹﯺﯻﯼﯽﯾﯿﰀﰁﰂﰃﰄﰅﰆﰇﰈﰉﰊﰋﰌﰍﰎﰏﰐﰑﰒﰓﰔﰕﰖﰗﰘﰙﰚﰛﰜﰝﰞﰟﰠﰡﰢﰣﰤﰥﰦﰧﰨﰩﰪﰫﰬﰭﰮﰯﰰﰱﰲﰳ"
    page_534 = "ﭑﭒﭓﭔﭕﭖﭗﭘﭙﭚﭛﭜﭝﭞﭟﭠﭡﭢﭣﭤﭥﭦﭧﭨﭩﭪﭫﭬﭭﭮﭯﭰﭱﭲﭳﭴﭵﭶﭷﭸﭹﭺﭻﭼﭽﭾﭿﮀﮁﮂﮃﮄﮅﮆﮇﮈﮉﮊﮋﮌﮍﮎﮏﮐﮑﮒﮓﮔﮕﮖﮗﮘﮙﮚﮛﮜﮝﮞﮟﮠﮡﮢﮣﮤﮥﮦﮧﮨﮩﮪﮫﮬﮭﮮﮯﮰﮱﯓﯔﯕﯖﯗﯘﯙﯚﯛﯜﯝﯞﯟﯠﯡﯢﯣﯤﯥﯦﯧﯨﯩﯪﯫﯬﯭﯮﯯ"

    1.upto(604) do |page|
      word_index = 0

      Verse.unscoped.where(page_number: page).order("verse_index asc").each do |v|
        v.words.order("position asc").each do |word|

          if page == 576
            code = page_576[word_index].unpack("U*")[0]

            word.code_hex_v3 = code.to_s(16)
            word.code_dec_v3 = code
          elsif page == 534
            code = page_534[word_index].unpack("U*")[0]

            word.code_hex_v3 = code.to_s(16)
            word.code_dec_v3 = code
          else
            word.code_hex_v3 = (64577 + word_index).to_s(16)
            word.code_dec_v3 = 64577 + word_index
          end
          word.save validate: false
          word_index += 1
        end
      end
    end
  end

  task add_slugs: :environment do
    PaperTrail.enabled = false
    Translation.where(resource_content_id: [140, 133, 110, 35]).find_each do |trans|
      trans.update_column :text, trans.text.gsub(/\d+[.]/, '').strip
    end && true
    Translation.where(resource_content_id: 95).find_each do |trans|
      trans.update_column :text, trans.text.sub(/\(\d+:\d+\)\s/, '').strip
    end

    Chapter.includes(translated_names: :language).find_each do |c|
      c.translated_names.each do |t|
        c.add_slug(t.name, t.language.iso_code)

        c.add_slug(c.name_simple, t.language.iso_code)
        c.add_slug(c.name_complex, t.language.iso_code)

        c.add_slug("surah #{c.name_simple}", t.language.iso_code)
        c.add_slug("surah #{c.name_complex}", t.language.iso_code)

        c.add_slug(c.name_arabic, 'ar')
        c.add_slug("#{c.name_arabic} سورہ", 'ar')

        c.add_slug("quran #{c.chapter_number.ordinalize} surah", 'en')
      end
    end
  end

  task move_urdu_transliteration: :environment do
    PaperTrail.enabled = false

    urdu = Language.find_by(name: 'Urdu')
    data_source = DataSource.find_by(name: 'Quran.com')
    author = Author.where(name: "Quran.com").first_or_create
    ur_translation_resource = ResourceContent.find(104)

    ur_wbw_transliteration_resource = ResourceContent.where(
        cardinality_type: ResourceContent::CardinalityType::OneWord,
        resource_type: ResourceContent::ResourceType::Content,
        sub_type: ResourceContent::SubType::Translation,
        language: urdu,
        author: author,
        author_name: author.name,
        data_source: data_source,
        language_name: urdu.name.downcase,
        slug: 'urdu-wbw-translation'
    ).first_or_create

    ur_ayah_transliteration_resource = ResourceContent.where(
        cardinality_type: ResourceContent::CardinalityType::OneVerse,
        resource_type: ResourceContent::ResourceType::Content,
        sub_type: ResourceContent::SubType::Translation,
        language: urdu,
        author: author,
        author_name: author.name,
        data_source: data_source,
        language_name: urdu.name.downcase,
        slug: 'urdu-transliteration',
        name: 'Urdu/Arabic Transliteration'
    ).first_or_create


    Translation.where(resource_content: ur_ayah_transliteration_resource).delete_all
    Transliteration.where(resource_content: ur_wbw_transliteration_resource).delete_all

    ArabicTransliteration.includes(:word).find_each do |a|
      a.word.update_attributes!(text_indopak: a.indopak_text) if a.indopak_text.presence

      a.word.translations.where(language: urdu).first_or_create.update_attributes!(text: a.ur_translation, resource_content: ur_translation_resource, language_name: urdu.name.downcase)
      a.word.transliterations.where(language: urdu).first_or_create!(text: a.text, resource_content: ur_wbw_transliteration_resource, language_name: urdu.name.downcase)
    end

    Verse.find_each do |v|
      ur_transliteration = v.words.order('position asc').map do |w|
        "<span>#{w.arabic_transliteration&.text}</span>"
      end.join(' ')
      v.translations.where(resource_content: ur_ayah_transliteration_resource).first_or_create(text: ur_transliteration, language: urdu, language_name: urdu.name.downcase)
    end
  end

  task format_indopak_num: :environment do
    def change_number(n)
      mapping = {
          "٠" => "۰﻿",
          "١" => "۱﻿",
          "٢" => "۲﻿",
          "٣" => "۳﻿",
          "٤" => "۴﻿",
          "٥" => "۵﻿",
          "٦" => "۶﻿",
          "٧" => "۷",
          "٨" => "۸",
          "٩" => "۹﻿"
      }
      n.chars.map do |c|
        mapping[c]
      end.join('')
    end

    ayah_marker = "(%{number})"
    marker = "﴿%{number}﻿﴾"

    File.open("output_6.txt", "wb") do |f|
      content = File.open("input.txt").read
      output = content.gsub(reg) do
        format marker, number: change_number($1)
      end
      f << output
    end
  end

  def format_ayah_number(number)
    # numbers = '۰,۱,۲,۳,۴,۵,۶,۷,۸,۹'.split(',')
    numbers = ["۰", "۱", "۲", "۳", "۴", "۵", "۶", "۷", "۸", "۹"]
    ayah_marker = "﴿%{number}﴾"

    converted = number.to_s.chars.map do |c|
      numbers[c.to_i]
    end.join('')

    format ayah_marker, number: converted
  end

  task export_indopak: :environment do
    db = "#{Rails.root}/data/ar_naskh.db"

    connection = {
        adapter: 'sqlite3',
        database: db
    }

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

    class ExportFootnoteRecord < ExportRecord
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

    ExportRecord.establish_connection connection
    ExportRecord.table_name = 'arabic_text'

    File.open "indopak_.txt", "wb" do |file|
      Verse.order("verse_index ASC").each do |v|
        #  ExportRecord.where(sura: v.chapter_id, ayah: v.verse_number).update_all text: "#{v.text_indopak}#{format_ayah_number v.verse_number}"
        file.puts "#{v.text_indopak}#{format_ayah_number v.verse_number}"
      end
    end

  end

  task import_ur_ibne_kathir: :environment do
    class UrTafsir < ActiveRecord::Base
    end

    PaperTrail.enabled = false

    UrTafsir.establish_connection({
                                      adapter: 'sqlite3',
                                      database: "#{Rails.root}/ibnekathir.ur.db"

                                  })

    UrTafsir.table_name = 'verses'
    l = Language.find_by_iso_code('ur')
    data_source = DataSource.where(name: "GreentechApps", url: 'https://github.com/GreentechApps/').first_or_create
    resource = ResourceContent.where(author_id: 96, data_source: data_source, author_name: "ابن كثير", resource_type: "content", sub_type: "tafsir", name: "ابن كثيراردو", description: nil, cardinality_type: "1_ayah", language_id: l.id, language_name: l.name.downcase, slug: "ur_ibn_kathir").first_or_create

    UrTafsir.all.each do |t|
      verse = Verse.find_by_verse_key("#{t.sura}:#{t.ayah}")
      Tafsir.where(verse_key: verse.verse_key, verse_id: verse.id, language_id: l.id, resource_content_id: resource.id).first_or_create.update_attributes(text: t.text, language_name: l.name.downcase, resource_name: resource.name)
    end
  end

  task import_ukrainian_with_footnote: :environment do
    PaperTrail.enabled = false
    author = Author.where(name: 'Mykhaylo Yakubovych').first_or_create
    language = Language.find_by_name 'Ukrainian'

    resource_content = ResourceContent.where({
                                                 author_id: author.id,
                                                 author_name: author.name,
                                                 resource_type: "content",
                                                 sub_type: "translation",
                                                 name: author.name,
                                                 description: 'Якубович Extracted by: crimean.org',
                                                 cardinality_type: "1_ayah",
                                                 language_id: language.id,
                                                 language_name: "ukrainian",
                                                 slug: 'mykhaylo-yakubovych-with-tafsir'}).first_or_create

    footnote_resource_content = ResourceContent.where({
                                                          author_id: author.id,
                                                          author_name: author.name,
                                                          resource_type: "content",
                                                          sub_type: "footnote",
                                                          name: 'Якубович Extracted by: crimean.org',
                                                          description: 'Якубович Extracted by: crimean.org',
                                                          cardinality_type: "1_ayah",
                                                          language_id: language.id,
                                                          language_name: "ukrainian",
                                                          slug: 'mykhaylo-yakubovych-footnote'}).first_or_create

    url = "https://gist.githubusercontent.com/naveed-ahmad/b642d6b22ca020f5f385b7e983e1ceb9/raw/21ee6a78b92c929e175b1151e478cc4bbf1e8d07/transaction.docx.html"

    text = if Rails.env.development?
             File.open("lib/data/transaction.docx.html").read
           else
             open(url).read
           end

    docs = Nokogiri.parse(text)

    docs.search("body > .c1").each_with_index do |verse_node, v_index|
      text = verse_node.text.to_s.split("|")[2].to_s.strip

      if verse = Verse.find_by_verse_index(v_index + 1)
        translation = verse.translations.where(resource_content: resource_content).first_or_create
        translation.foot_notes.delete_all

        verse_node.search("a").each_with_index do |footnote_node, f_i|
          footnote_id = footnote_node.attributes['href'].value
          number = footnote_id.scan(/\d/).join('')
          # footnote_text = docs.search(footnote_id).first.parent.search('span').text.strip
          footnote_text = docs.search(footnote_id).first.parent.search('.c4').text.strip

          footnote = translation.foot_notes.create(text: footnote_text, language: language, language_name: language.name.downcase, resource_content: footnote_resource_content)

          text = text.gsub("[#{number}]#{number}", "<sup foot_note=#{footnote.id}>#{f_i + 1}</sup>")
        end

        translation.text = text.strip
        translation.language = language
        translation.language_name = language.name.downcase
        translation.resource_name = resource_content.name
        translation.save
        puts "update translation #{translation.id}"
      end
    end
  end

  SEE_MORE_REF_REGEXP = Regexp.new('(?<ref>\d+:\d+)')
  SEE_MORE_TEXT_REGEXP = Regexp.new("(see|footnote)")

  def process_foot_note_text(foot_note_node)
    foot_note_node.search("span").each do |node|
      if node.attr('class').to_s.strip == 'c14'
        node.name = "sup"
        node.remove_attribute("class")
      end
    end

    # remove links
    foot_note_node.search("a").remove

    white_list_sanitizer = Rails::Html::WhiteListSanitizer.new

    sanitized = white_list_sanitizer.sanitize(foot_note_node.to_s.strip, tags: %w(div sup p ol ul li), attributes: []).gsub(/[\r\n]+/, "<br/>")

    sanitized.gsub(SEE_MORE_REF_REGEXP) do
      "<a href='/#{Regexp.last_match(1)}' class='see-more footnote'>#{Regexp.last_match(1)}</a>"
    end
  end

  task import_musfata_khitab_with_footnote: :environment do
    PaperTrail.enabled = false

    author = Author.where(name: 'Dr. Mustafa Khattab').first_or_create
    language = Language.find_by_name 'English'
    data_source = DataSource.where(name: 'Quran.com').first_or_create

    url = "https://raw.githubusercontent.com/naveed-ahmad/Quran-text/master/clearquran-2019.html"

    text = open(url).read
    docs = Nokogiri.parse(text)
    a = 2

    resource_content = ResourceContent.where({
                                                 author_id: author.id,
                                                 author_name: author.name,
                                                 resource_type: "content",
                                                 sub_type: "translation",
                                                 name: author.name,
                                                 description: 'Dr. Mustafa Khattab, The Clear Quran(With Tafsir)',
                                                 cardinality_type: "1_ayah",
                                                 language_id: language.id,
                                                 language_name: "english",
                                                 data_source: data_source,
                                                 slug: 'clearquran-with-tafsir'}).first_or_create

    footnote_resource_content = ResourceContent.where({
                                                          author_id: author.id,
                                                          author_name: author.name,
                                                          resource_type: "content",
                                                          sub_type: "footnote",
                                                          name: 'Dr. Mustafa Khattab, The Clear Quran footnotes(With Tafsir)',
                                                          description: 'Dr. Mustafa Khattab, The Clear Quran footnotes(With Tafsir)',
                                                          cardinality_type: "1_ayah",
                                                          language_id: language.id,
                                                          language_name: "english",
                                                          data_source: data_source,
                                                          slug: 'clearquran-with-tafsir-footnote'}).first_or_create


    docs.search('ol .c1').each_with_index do |verse_node, v_index|
      text = verse_node.text.strip
      verse = Verse.find_by_verse_index(v_index + 1)
      translation = verse.translations.where(resource_content: resource_content).first_or_create
      translation.language = language
      translation.language_name = language.name.downcase
      translation.resource_name = resource_content.name

      translation.save
      translation.foot_notes.delete_all

      verse_node.search("a").each_with_index do |footnote_node, f_i|
        footnote_id = footnote_node.attributes['href'].value
        number = footnote_id.scan(/\d/).join('')

        footnote_text = process_foot_note_text(docs.search(footnote_id).first.parent.parent)
        footnote = translation.foot_notes.create(text: footnote_text, language: language, language_name: 'english', resource_content: footnote_resource_content)

        text = text.gsub("[#{number}]", "<sup foot_note=#{footnote.id}>#{f_i + 1}</sup>")
      end

      translation.text = text.strip
      translation.save
      puts "update translation #{translation.id}"
    end
  end

  task add_urdu_wbw_translation2: :environment do
    class WbwTranslation < ActiveRecord::Base
      self.establish_connection({adapter: 'sqlite3',
                                 database: "#{Rails.root}/db/data/urdu_wbw.db"
                                })

      self.table_name = "quran_word"
    end

    CSV.open "urdu_translations_final_with_source_with_fix_5.csv", 'w' do |csv|
      csv << ['word_id', 'word_position', 'surah_number', 'ayah_number', 'source_arabic', 'quran_arabic', 'source_urdu', 'urdu', 'final_urdu', 'english', 'urdu_author']

      WbwTranslation.where(SurahNumber: 2).find_each do |v|
        words_hashmi = v.Word_Hashmi.split(']').each do |s|
          s.tr! '[', ''
        end

        words_nazar = v.Word_Nazar.split(']').each do |s|
          s.tr! '[', ''
        end

        quran_verse = Verse.find_by_verse_key "#{v.SurahNumber}:#{v.AyahNumber}"
        quran_words = quran_verse.words.includes(:en_translation).where(char_type_id: 1).order('position asc')

        final_words, author = if (words_nazar.length - quran_words.length).abs <= (words_nazar.length - quran_words.length).abs
                                [words_hashmi, 'hashmi']
                              else
                                [words_nazar, 'nazar']
                              end

        urdu_trans = ''
        join_trans = false
        word_joined = 0
        quran_word_index = 0

        final_words.each_with_index do |word, i|
          arabic, urdu = word.split(':').map(&:strip!)
          arabic = arabic.to_s
          source_urdu = urdu.to_s
          urdu = urdu.to_s

          quran_word = quran_words[quran_word_index]
          text_madani = quran_word.try(:text_madani).to_s

          if join_trans && final_words[i + 1 + word_joined]
            #urdu_trans = "#{urdu_trans} #{urdu}"
            next_word = final_words[i + 1 + word_joined]
            arabic_n, urdu = next_word.split(':').map(&:strip!)
            urdu_trans = nil
          else
            if text_madani.include?(arabic) && text_madani != arabic && final_words[i + 1 + word_joined]
              #join translation with next word
              next_word = final_words[i + 1 + word_joined]
              arabic_n, urdu_next = next_word.split(':').map(&:strip!)

              urdu_trans = "#{urdu} #{urdu_next}".strip
              join_trans = true
            else
              join_trans = false
              urdu_trans = ''
            end
          end

          english = quran_word.try(:en_translation).try(:text)

          csv << [quran_word.try(:id), quran_word.try(:position), v.SurahNumber, v.AyahNumber, arabic.to_s.strip, quran_word.try(:text_madani), source_urdu, urdu.to_s.strip, urdu_trans, english, author]
        end
        word_joined = 0
        quran_word_index = 0

        puts "#{v.SurahNumber}:#{v.AyahNumber}"
      end
    end
  end

  task add_urdu_wbw_translation: :environment do
    class WbwTranslation < ActiveRecord::Base
      self.establish_connection({adapter: 'sqlite3',
                                 database: "#{Rails.root}/db/data/urdu_wbw.db"
                                })

      self.table_name = "quran_word"
    end

    CSV.open "urdu_translations_final_with_source.csv", 'w' do |csv|
      csv << ['word_id', 'word_position', 'surah_number', 'ayah_number', 'source_arabic', 'quran_arabic', 'source_urdu', 'urdu', 'final_urdu', 'english', 'urdu_author']

      WbwTranslation.find_each do |v|
        words_hashmi = v.Word_Hashmi.split(']').each do |s|
          s.tr! '[', ''
        end

        words_nazar = v.Word_Nazar.split(']').each do |s|
          s.tr! '[', ''
        end

        quran_verse = Verse.find_by_verse_key "#{v.SurahNumber}:#{v.AyahNumber}"
        quran_words = quran_verse.words.includes(:en_translation).where(char_type_id: 1).order('position asc')

        final_words, author = if (words_nazar.length - quran_words.length).abs <= (words_nazar.length - quran_words.length).abs
                                [words_hashmi, 'hashmi']
                              else
                                [words_nazar, 'nazar']
                              end

        urdu_trans = ''
        join_trans = false

        final_words.each_with_index do |word, i|
          arabic, urdu = word.split(':').map(&:strip!)
          arabic = arabic.to_s
          source_urdu = urdu.to_s
          urdu = urdu.to_s

          quran_word = quran_words[i]
          text_madani = quran_word.try(:text_madani).to_s

          if join_trans && final_words[i + 1]
            #urdu_trans = "#{urdu_trans} #{urdu}"
            next_word = final_words[i + 1]
            arabic_n, urdu = next_word.split(':').map(&:strip!)
            urdu_trans = nil
          else
            if text_madani.include?(arabic) && text_madani != arabic && final_words[i + 1]
              #join translation with next word
              next_word = final_words[i + 1]
              arabic_n, urdu_next = next_word.split(':').map(&:strip!)

              urdu_trans = "#{urdu} #{urdu_next}".strip
              join_trans = true
            else
              join_trans = false
              urdu_trans = ''
            end
          end

          english = quran_word.try(:en_translation).try(:text)

          csv << [quran_word.try(:id), quran_word.try(:position), v.SurahNumber, v.AyahNumber, arabic.to_s.strip, quran_word.try(:text_madani), source_urdu, urdu.to_s.strip, urdu_trans, english, author]
        end

        puts "#{v.SurahNumber}:#{v.AyahNumber}"
      end
    end
  end
end
