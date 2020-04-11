namespace :one_time do
  task prepare_uthmani_simple: :environment do
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

    codes = codes.gsub(/s+/,'')

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
    page_534="ﭑﭒﭓﭔﭕﭖﭗﭘﭙﭚﭛﭜﭝﭞﭟﭠﭡﭢﭣﭤﭥﭦﭧﭨﭩﭪﭫﭬﭭﭮﭯﭰﭱﭲﭳﭴﭵﭶﭷﭸﭹﭺﭻﭼﭽﭾﭿﮀﮁﮂﮃﮄﮅﮆﮇﮈﮉﮊﮋﮌﮍﮎﮏﮐﮑﮒﮓﮔﮕﮖﮗﮘﮙﮚﮛﮜﮝﮞﮟﮠﮡﮢﮣﮤﮥﮦﮧﮨﮩﮪﮫﮬﮭﮮﮯﮰﮱﯓﯔﯕﯖﯗﯘﯙﯚﯛﯜﯝﯞﯟﯠﯡﯢﯣﯤﯥﯦﯧﯨﯩﯪﯫﯬﯭﯮﯯ"

    1.upto(604) do |page|
      word_index = 0

      Verse.unscoped.where(page_number: page).order("verse_index asc").each do |v|
        v.words.order("position asc").each do |word|

          if page == 576
            code = page_576[word_index].unpack("U*")[0]

            word.code_hex_v3 = code.to_s(16)
            word.code_dec_v3 = code
          elsif  page == 534
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
       a.word.update_attributes!(text_indopak:  a.indopak_text) if a.indopak_text.presence

       a.word.translations.where(language: urdu).first_or_create.update_attributes!(text: a.ur_translation, resource_content: ur_translation_resource, language_name: urdu.name.downcase)
       a.word.transliterations.where(language: urdu).first_or_create!(text: a.text, resource_content: ur_wbw_transliteration_resource, language_name: urdu.name.downcase)
    end

    Verse.find_each do |v|
     ur_transliteration = v.words.order('position asc').map do |w| "<span>#{w.arabic_transliteration&.text}</span>" end.join(' ')
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

    ayah_marker= "(%{number})"
    marker = "﴿%{number}﻿﴾"



    File.open("output_6.txt", "wb") do |f|
      content = File.open("input.txt").read
      output = content.gsub(reg) do
        format marker, number: change_number($1)
      end
      f << output
    end
  end

  def process_foot_note_text_for_chechen(foot_note_node, chapter)
      bold_dom = {
          2 => 'c26',
          4 => "c21",
          5 => "c3 c13 c40",
          10 => "c12 c30"
      }
     foot_note_node.search("span").each do |node|
      if bold_dom[chapter.id]  && node.attr('class').to_s.strip == bold_dom[chapter.id]
        node.name = "b"
        node.remove_attribute("class")
      end
    end

    # remove links
    foot_note_node.search("a").remove

    white_list_sanitizer = Rails::Html::WhiteListSanitizer.new
    white_list_sanitizer.sanitize(foot_note_node.to_s.strip, tags: %w(div sup p ol ul li b), attributes: []).gsub(/[\r\n]+/, "<br/>")
  end

  task import_chechen_with_footnote: :environment do
    PaperTrail.enabled = false

    # issues
    # 23 last ayah
    # 35 last ayah
    # 1 last ayah
    # 62
    # 9 last three ayah

    # TODO: Fix author name
    author   = Author.where(name: 'Magomed Magomedov').first_or_create
    language = Language.find_by_name 'Chechen'
    data_source = DataSource.where(name: "Movsar Bekaev - bekaev.movsar@gmail.com").first_or_create

    resource_content = ResourceContent.where({
                                                 author_id:        author.id,
                                                 author_name:      author.name,
                                                 resource_type:    "content",
                                                 sub_type:         "translation",
                                                 name:             author.name,
                                                 description:      'Chechen',
                                                 cardinality_type: "1_ayah",
                                                 language_id:      language.id,
                                                 language_name:    "chechen",
                                                 slug:             'chechen-translation',
                                                 data_source: data_source
                                             }).first_or_create

    footnote_resource_content = ResourceContent.where({
                                                          author_id:        author.id,
                                                          author_name:      author.name,
                                                          resource_type:    "content",
                                                          sub_type:         "footnote",
                                                          name:             author.name,
                                                          description:      "#{author.name} - Chechen translation",
                                                          cardinality_type: "1_ayah",
                                                          language_id:      language.id,
                                                          language_name:    "chechen",
                                                          slug:             'chechen-footnote',
                                                          data_source: data_source
                                                      }).first_or_create

    translation=nil
    Dir['chechen/*'].each do |f|
      text = File.open(f).read
      docs = Nokogiri.parse(text)
      chapter = Chapter.find(f[/\d+/])

      verses  = Verse.unscoped.where(chapter_id: chapter.id).order("verse_index ASC")

      if docs.search("li").length != verses.count
        binding.pry
      end

      docs.search("li").each_with_index do |verse_node, v_index|
        text        = verse_node.text.strip
        verse       = verses[v_index]
        translation = verse.translations.where(resource_content: resource_content, language: language).first_or_initialize
        translation.save validate: false
        translation.foot_notes.delete_all

        puts "TRANSLATIONS  #{translation.id}"

        verse_node.search("a").each_with_index do |footnote_node, f_i|
          footnote_id = footnote_node.attributes['href'].value
          number      = footnote_id.scan(/\d/).join('')

          footnote_text = process_foot_note_text_for_chechen(docs.search(footnote_id).first.parent.parent, chapter)
          footnote      = translation.foot_notes.create(text: footnote_text, language: language, language_name: language.name.downcase, resource_content: footnote_resource_content)

          text = text.gsub("[#{number}]", "<sup foot_note=#{footnote.id}>#{f_i + 1}</sup>")
        end

        translation.text          = text.strip
        translation.language      = language
        translation.language_name = language.name.downcase
        translation.resource_name = resource_content.name
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
                                    adapter:  'sqlite3',
                                    database: "#{Rails.root}/ibnekathir.ur.db"
    
                                  })

    UrTafsir.table_name='verses'
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
    author             = Author.where(name: 'Mykhaylo Yakubovych').first_or_create
    language           = Language.find_by_name 'Ukrainian'
    
    resource_content = ResourceContent.where({
                                               author_id:        author.id,
                                               author_name:      author.name,
                                               resource_type:    "content",
                                               sub_type:         "translation",
                                               name:             author.name,
                                               description:      'Якубович Extracted by: crimean.org',
                                               cardinality_type: "1_ayah",
                                               language_id:      language.id,
                                               language_name:    "ukrainian",
                                               slug:             'mykhaylo-yakubovych-with-tafsir' }).first_or_create
    
    footnote_resource_content = ResourceContent.where({
                                                        author_id:        author.id,
                                                        author_name:      author.name,
                                                        resource_type:    "content",
                                                        sub_type:         "footnote",
                                                        name:             'Якубович Extracted by: crimean.org',
                                                        description:      'Якубович Extracted by: crimean.org',
                                                        cardinality_type: "1_ayah",
                                                        language_id:      language.id,
                                                        language_name:    "ukrainian",
                                                        slug:             'mykhaylo-yakubovych-footnote' }).first_or_create
    
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
          number      = footnote_id.scan(/\d/).join('')
          # footnote_text = docs.search(footnote_id).first.parent.search('span').text.strip
          footnote_text = docs.search(footnote_id).first.parent.search('.c4').text.strip
          
          footnote = translation.foot_notes.create(text: footnote_text, language: language, language_name: language.name.downcase, resource_content: footnote_resource_content)
          
          text = text.gsub("[#{number}]#{number}", "<sup foot_note=#{footnote.id}>#{f_i + 1}</sup>")
        end
        
        translation.text          = text.strip
        translation.language      = language
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
    
    author   = Author.where(name: 'Dr. Mustafa Khattab').first_or_create
    language = Language.find_by_name 'English'
    data_source = DataSource.where(name: 'Quran.com').first_or_create
    
    url = "https://raw.githubusercontent.com/naveed-ahmad/Quran-text/master/clearquran-2019.html"
    
    text = open(url).read
    docs = Nokogiri.parse(text)
    a=2

    resource_content = ResourceContent.where({
                                               author_id:        author.id,
                                               author_name:      author.name,
                                               resource_type:    "content",
                                               sub_type:         "translation",
                                               name:             author.name,
                                               description:      'Dr. Mustafa Khattab, The Clear Quran(With Tafsir)',
                                               cardinality_type: "1_ayah",
                                               language_id:      language.id,
                                               language_name:    "english",
                                               data_source: data_source,
                                               slug:             'clearquran-with-tafsir' }).first_or_create
    
    footnote_resource_content = ResourceContent.where({
                                                        author_id:        author.id,
                                                        author_name:      author.name,
                                                        resource_type:    "content",
                                                        sub_type:         "footnote",
                                                        name:             'Dr. Mustafa Khattab, The Clear Quran footnotes(With Tafsir)',
                                                        description:      'Dr. Mustafa Khattab, The Clear Quran footnotes(With Tafsir)',
                                                        cardinality_type: "1_ayah",
                                                        language_id:      language.id,
                                                        language_name:    "english",
                                                        data_source:       data_source,
                                                        slug:             'clearquran-with-tafsir-footnote' }).first_or_create
    
    
    docs.search('ol .c1').each_with_index do |verse_node, v_index|
      text        = verse_node.text.strip
      verse       = Verse.find_by_verse_index(v_index + 1)
      translation = verse.translations.where(resource_content: resource_content).first_or_create
      translation.language = language
      translation.language_name = language.name.downcase
      translation.resource_name = resource_content.name

      translation.save
      translation.foot_notes.delete_all

      verse_node.search("a").each_with_index do |footnote_node, f_i|
        footnote_id = footnote_node.attributes['href'].value
        number      = footnote_id.scan(/\d/).join('')
        
        footnote_text = process_foot_note_text(docs.search(footnote_id).first.parent.parent)
        footnote      = translation.foot_notes.create(text: footnote_text, language: language, language_name: 'english', resource_content: footnote_resource_content)
        
        text = text.gsub("[#{number}]", "<sup foot_note=#{footnote.id}>#{f_i + 1}</sup>")
      end
      
      translation.text          = text.strip
      translation.save
      puts "update translation #{translation.id}"
    end
  end
  
  task add_urdu_wbw_translation2: :environment do
    class WbwTranslation < ActiveRecord::Base
      self.establish_connection({ adapter:  'sqlite3',
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
        
        urdu_trans       = ''
        join_trans       = false
        word_joined      = 0
        quran_word_index = 0
        
        final_words.each_with_index do |word, i|
          arabic, urdu = word.split(':').map(&:strip!)
          arabic       = arabic.to_s
          source_urdu  = urdu.to_s
          urdu         = urdu.to_s
          
          quran_word  = quran_words[quran_word_index]
          text_madani = quran_word.try(:text_madani).to_s
          
          if join_trans && final_words[i + 1 + word_joined]
            #urdu_trans = "#{urdu_trans} #{urdu}"
            next_word      = final_words[i + 1 + word_joined]
            arabic_n, urdu = next_word.split(':').map(&:strip!)
            urdu_trans     = nil
          else
            if text_madani.include?(arabic) && text_madani != arabic && final_words[i + 1 + word_joined]
              #join translation with next word
              next_word           = final_words[i + 1 + word_joined]
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
        word_joined      = 0
        quran_word_index = 0
        
        puts "#{v.SurahNumber}:#{v.AyahNumber}"
      end
    end
  end
  
  task add_urdu_wbw_translation: :environment do
    class WbwTranslation < ActiveRecord::Base
      self.establish_connection({ adapter:  'sqlite3',
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
          arabic       = arabic.to_s
          source_urdu  = urdu.to_s
          urdu         = urdu.to_s
          
          quran_word  = quran_words[i]
          text_madani = quran_word.try(:text_madani).to_s
          
          if join_trans && final_words[i + 1]
            #urdu_trans = "#{urdu_trans} #{urdu}"
            next_word      = final_words[i + 1]
            arabic_n, urdu = next_word.split(':').map(&:strip!)
            urdu_trans     = nil
          else
            if text_madani.include?(arabic) && text_madani != arabic && final_words[i + 1]
              #join translation with next word
              next_word           = final_words[i + 1]
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
