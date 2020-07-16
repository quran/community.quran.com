namespace :one_time do
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

    codes = File.open("data/v2-font-codes.txt").read
    word_index = 0

    codes = ""

    1.upto(604).each do |p|
      page = File.open("#{Rails.root}/data/v2-codes/#{p}.txt").read
      codes += page
    end

=begin
    #NOTE: script for detecting difference in v1 and v2 pages
    pages = {}

    CSV.open("page_words.csv", 'wb') do |csv|
      csv << ["page", "v1 words", "v2 words", "difference v1-v2"]

      1.upto(604).each do |p|
        v2 = File.open("#{Rails.root}/data/v2-codes/#{p}.txt").read.gsub(/s+/,'').length
        v1 = Word.where(page_number: p).count
        csv << [p, v1, v2, v1 - v2]
      end
    end
=end

    codes = codes.gsub(/s+/, '')

    Verse.unscoped.order("verse_index asc").each do |v|
      v.words.order("position asc").each do |word|
        code = codes[word_index].unpack("U*")[0]

        word.code_hex_v3 = code.to_s(16)
        word.code_dec_v3 = code
        word.save validate: false
        word_index += 1
      end
    end
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

    page_chars = "ﱁﱂﱃﱄﱅﱆﱇﱈﱉﱊﱋﱌﱍﱎﱏﱐﱑﱒﱓﱔﱕﱖﱗﱘﱙﱚﱛﱜﱝﱞﱟﱠﱡﱢﱣﱤﱥﱦﱧﱨﱩﱪﱫﱬﱭﱮﱯﱰﱱﱲﱳﱴﱵﱶﱷﱸﱹﱺﱻﱼﱽﱾﱿﲀﲁﲂﲃﲄﲅﲆﲇﲈﲉﲊﲋﲌﲍﲎﲏﲐﲑﲒﲓﲔﲕﲖﲗﲘﲙﲚﲛﲜﲝﲞﲟﲠﲡﲢﲣﲤﲥﲦﲧﲨﲩﲪﲫﲬﲭﲮﲯﲰﲱﲲﲳﲴﲵﲶﲷﲸﲹﲺﲻﲼﲽﲾﲿﳀﳁﳂﳃﳄﳅﳆﳇﳈﳉﳊﳋﳌﳍﳎﳏﳐﳑﳒﳓﳔﳕﳖﳗﳘﳙﳚﳛﳜﳝﳞﳟﳠﳡﳢﳣﳤﳥﳦﳧﳨﳩﳪﳫﳬﳭﳮﳯﳰﳱﳲﳳﳴﳵﳶﳷﳸﳹﳺﳻﳼ"


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


  task import_chechen_with_footnote: :environment do
    PaperTrail.enabled = false

    mapping = {
        1 => 'li.c0',
        2 => 'li.c10',
        3 => 'li.c1.c5',
        4 => 'li.c8.c15',
        5 => 'li.c4',
        6 => 'li.c1',

        # 7 is showing 11
        # 7 => 'li.c1.c9',

        8 => 'li.c2',
        9 => 'li.c9.c20',
        10 => 'li.c9',
        11 => 'li.c5',
        12 => 'li.c4',
        13 => 'li.c5.c12',
        14 => 'li.c9',
        15 => 'li.c1',
        16 => 'li.c0.c11',
        17 => 'li.c12.c14',
        18 => 'li.c0.c1',
        19 => 'li.c4.c11',
        20 => 'li.c6',
        21 => 'li.c0.c11',
        22 => 'li.c7.c13',
        23 => 'li.c3',
        24 => 'li.c0',
        25 => 'li.c2',
        26 => 'p.c5.c7',
        27 => 'li.c1',
        28 => 'li.c6',
        29 => 'li.c1.c6',
        30 => 'li.c5',
        31 => 'li.c4',
        32 => 'li.c7',
        33 => 'li.c11',
        34 => 'li.c1.c6',
        35 => 'li.c11.c12',
        36 => 'li.c2',
        37 => 'li.c10.c12',
        38 => 'li.c7',
        39 => 'li.c5',
        40 => 'li.c10',
        41 => 'li.c8',
        42 => 'li.c15',
        43 => 'li.c3',
        44 => 'li.c11.c14',
        45 => 'li.c7',
        46 => 'li.c7',
        47 => 'li.c2',
        48 => 'li.c11.c13',
        49 => 'li.c5',
        50 => 'li.c9',
        51 => 'li.c2',
        52 => 'li.c7.c10',
        53 => 'li.c5',
        54 => 'li.c3',
        55 => 'li.c6',
        56 => 'li.c2',
        57 => 'li.c9',
        58 => 'li.c10.c15',
        59 => 'li.c5.c6',
        60 => 'li.c1.c15',
        61 => 'li.c5',
        62 => 'li.c6',
        63 => 'li.c14',
        64 => 'li.c3',
        65 => 'li.c1',
        66 => 'li.c7.c14',
        67 => 'li.c10',
        68 => 'li.c8.c10',
        69 => 'li.c1',
        70 => 'li.c7',
        71 => 'li.c2',
        72 => 'li.c0',
        73 => 'li.c17',
        74 => 'li.c10.c14',
        75 => 'li.c7.c14',
        76 => 'li.c0.c1',
        77 => 'li.c11',
        78 => 'li.c5',
        79 => 'li.c13',
        80 => 'li.c8.c12',
        81 => 'li.c6.c9',
        82 => 'li.c9',
        83 => 'li.c0.c8',
        84 => 'li.c2',
        85 => 'li.c2.c5',
        86 => 'li.c9',
        87 => 'li.c9',
        88 => 'li.c11',
        89 => 'li.c5',
        90 => 'li.c8',
        91 => 'li.c10',
        92 => 'li.c10',
        93 => 'li.c16.c18',
        94 => 'li.c7',
        95 => 'li.c3',
        96 => 'li.c8',
        97 => 'li.c4',
        98 => 'li.c0',
        99 => 'li.c18',
        100 => 'li.c8',
        101 => 'li.c9',
        102 => 'li.c5.c8',
        103 => 'li.c9',
        104 => 'li.c4.c10',
        105 => 'li.c8',
        106 => 'li.c11',
        107 => 'li.c5',
        108 => 'li.c4',
        109 => 'li.c5',
        110 => 'li.c7',
        111 => 'li.c9',
        112 => 'li.c1',
        113 => 'li.c20',
        114 => 'li.c17'
    }

    bismillah = '#bismillah'
    # issues
    # 23 last ayah
    # 35 last ayah
    # 1 last ayah
    # 62
    # 9 last three ayah

    author = Author.where(name: 'Magomed Magomedov').first_or_create
    language = Language.find_by_name 'Chechen'
    data_source = DataSource.where(name: "Movsar Bekaev - bekaev.movsar@gmail.com").first_or_create

    resource_content = ResourceContent.where({
                                                 author_id: author.id,
                                                 author_name: author.name,
                                                 resource_type: "content",
                                                 sub_type: "translation",
                                                 name: author.name,
                                                 description: 'Chechen',
                                                 cardinality_type: "1_ayah",
                                                 language_id: language.id,
                                                 language_name: "chechen",
                                                 slug: 'chechen-translation',
                                                 data_source: data_source
                                             }).first_or_create

    resource_content.priority = 4
    resource_content.save
    footnote_resource_content = ResourceContent.where({
                                                          author_id: author.id,
                                                          author_name: author.name,
                                                          resource_type: "content",
                                                          sub_type: "footnote",
                                                          name: author.name,
                                                          description: "#{author.name} - Chechen translation",
                                                          cardinality_type: "1_ayah",
                                                          language_id: language.id,
                                                          language_name: "chechen",
                                                          slug: 'chechen-footnote',
                                                          data_source: data_source
                                                      }).first_or_create

    Translation.where(resource_content: resource_content).delete_all
    FootNote.where(resource_content: footnote_resource_content).delete_all

    translation = nil

    bismillah = ".c21 .c15"


    Dir['chechen/*'].each do |f|
      text = File.open(f).read
      docs = Nokogiri.parse(text)
      chapter = Chapter.find(f[/\d+/])

      verses = Verse.unscoped.where(chapter_id: chapter.id).order("verse_index ASC")

      if docs.search(".c13").length != verses.count
        binding.pry
      end

      docs.search("li").each_with_index do |verse_node, v_index|
        text = verse_node.text.strip
        verse = verses[v_index]
        translation = verse.translations.where(resource_content: resource_content, language: language).first_or_initialize
        translation.save validate: false
        translation.foot_notes.delete_all

        puts "TRANSLATIONS  #{translation.id}"

        verse_node.search("a").each_with_index do |footnote_node, f_i|
          footnote_id = footnote_node.attributes['href'].value
          number = footnote_id.scan(/\d/).join('')

          footnote_text = process_foot_note_text_for_chechen(docs.search(footnote_id).first.parent.parent, chapter)
          footnote = translation.foot_notes.create(text: footnote_text, language: language, language_name: language.name.downcase, resource_content: footnote_resource_content)

          text = text.gsub("[#{number}]", "<sup foot_note=#{footnote.id}>#{f_i + 1}</sup>")
        end

        translation.text = text.strip
        translation.language = language
        translation.language_name = language.name.downcase
        translation.resource_name = resource_content.name
        translation.priority = resource_content.priority

        translation.save
      end
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
