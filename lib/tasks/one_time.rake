namespace :one_time do
  task add_slugs: :environment do
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


    Translation.where(resource_content:ur_ayah_transliteration_resource).delete_all
    Transliteration.where(resource_content:ur_wbw_transliteration_resource).delete_all


    ArabicTransliteration.includes(:word).find_each do |a|
       a.word.update_attributes!(text_indopak:  a.indopak_text) if a.indopak_text.presence

       a.word.translations.where(language: urdu).first_or_create.update_attributes!(text: a.ur_translation, resource_content: ur_translation_resource, language_name: urdu.name.downcase)
       a.word.transliterations.where(language: urdu).first_or_create!(text: a.text, resource_content: ur_wbw_transliteration_resource, language_name: urdu.name.downcase)
    end

    Verse.find_each do |v|
     ur_transliteration = v.words.order('position asc').map do |w| "<span>#{w.arabic_transliteration&.text}</span>" end.join(' ')
      # v.transliterations.where(language: urdu).first_or_create(text: ur_transliteration, resource_content: ur_ayah_transliteration_resource, language_name: urdu.name.downcase)
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

    r = /[١|٢|٤|٥|٣]/

    text="بِسۡمِ ٱللَّهِ ٱلرَّحۡمَٰنِ ٱلرَّحِيمِ ١ ٱلۡحَمۡدُ لِلَّهِ رَبِّ ٱلۡعَٰلَمِينَ ٢ ٱلرَّحۡمَٰنِ ٱلرَّحِيمِ ٣ مَٰلِكِ يَوۡمِ ٱلدِّينِ ٤ إِيَّاكَ نَعۡبُدُ وَإِيَّاكَ نَسۡتَعِينُ ٥ ٱهۡدِنَا ٱلصِّرَٰطَ ٱلۡمُسۡتَقِيمَ ٦ صِرَٰطَ ٱلَّذِينَ أَنۡعَمۡتَ عَلَيۡهِمۡ غَيۡرِ ٱلۡمَغۡضُوبِ عَلَيۡهِمۡ وَلَا ٱلضَّآلِّينَ ٧"

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


  def encode_and_clean_text(text)
    if text.valid_encoding?
      text
    else
      text.scrub!
    end.to_s
      .sub('#', '')
      .sub('#VALUE!', '')
      .strip
  end
  
  def parse_indonesian_sabiq(rows, resource)
    footnote_resource_content = ResourceContent.where({
                                                        author_id:        resource.author_id,
                                                        author_name:      resource.author.name,
                                                        resource_type:    "content",
                                                        sub_type:         "footnote",
                                                        name:             resource.name,
                                                        description:      "#{resource.name} footnotes",
                                                        cardinality_type: "1_ayah",
                                                        language_id:      resource.language.id,
                                                        language_name:    resource.language.name.downcase,
                                                      }).first_or_create
    
    rows.each do |row|
      verse = Verse.find_by_verse_key("#{row[1]}:#{row[2]}")
      
      text     = encode_and_clean_text(row[3].to_s).sub(/\d+./, '')
      footnote = encode_and_clean_text(row[4].to_s)
      
      translation               = verse.translations.where(resource_content: resource).first_or_create
      translation.language      = resource.language
      translation.language_name = resource.language.name.downcase
      translation.resource_name = resource.name
      translation.foot_notes.delete_all
      translation.save

      footnote_ids = text.scan(/[\*]+\(\d+\)/)
      footnotes    = footnote.split(/[\*]+\d+./).select(&:present?)
      
      footnote_ids.each_with_index do |node, i|
        footnote = translation.foot_notes.create(text: footnotes[i].to_s.strip, language: resource.language, language_name: resource.language.name.downcase, resource_content: footnote_resource_content)
        
        text = text.gsub("#{node}", "<sup foot_note=#{footnote.id}>#{i + 1}</sup>")
      end
      
      if footnote_ids.blank? && footnotes.present?
        footnote = translation.foot_notes.create(text: footnotes.join("\n"), language: resource.language, language_name: resource.language.name.downcase, resource_content: footnote_resource_content)
        
        text = ("#{text}" "<sup foot_note=#{footnote.id}>1</sup>")
      end
      
      translation.text = text
      translation.save
      
      puts translation.id
    end
  end
  
  def parse_portuguese_nasr(rows, resource)
    footnote_resource_content = ResourceContent.where({
                                                        author_id:        resource.author_id,
                                                        author_name:      resource.author.name,
                                                        resource_type:    "content",
                                                        sub_type:         "footnote",
                                                        name:             resource.name,
                                                        description:      "#{resource.name} footnotes",
                                                        cardinality_type: "1_ayah",
                                                        language_id:      resource.language.id,
                                                        language_name:    resource.language.name.downcase,
                                                      }).first_or_create

    resource.save
    rows.each do |row|
      verse = Verse.find_by_verse_key("#{row[1]}:#{row[2]}")
      
      text     = encode_and_clean_text(row[3].to_s)
      footnote = encode_and_clean_text(row[4].to_s)


      translation               = verse.translations.where(resource_content_id: resource.id).first_or_create
      translation.language      = resource.language
      translation.language_name = resource.language.name.downcase
      translation.resource_name = resource.name
      translation.foot_notes.delete_all
      translation.text = text

      translation.save(validate: false) rescue translation.save

      if footnote.present?
        _footnote = translation.foot_notes.create(text: footnote, language: resource.language, language_name: resource.language.name.downcase, resource_content: footnote_resource_content)
        
        text = ("#{text}" "<sup foot_note=#{_footnote.id}>1</sup>")
      end
      
      translation.text = text
      translation.save
      
      puts translation.id
    end
  end
  
  def parse_uzbek_mansour(rows, resource)
    footnote_resource_content = ResourceContent.where({
                                                        author_id:        resource.author_id,
                                                        author_name:      resource.author.name,
                                                        resource_type:    "content",
                                                        sub_type:         "footnote",
                                                        name:             resource.name,
                                                        description:      "#{resource.name} footnotes",
                                                        cardinality_type: "1_ayah",
                                                        language_id:      resource.language.id,
                                                        language_name:    resource.language.name.downcase,
                                                      }).first_or_create
  
    rows.each do |row|
      verse = Verse.find_by_verse_key("#{row[1]}:#{row[2]}")
    
      text     = encode_and_clean_text(row[3].to_s).sub(/\d+./, '')
      footnote = encode_and_clean_text(row[4].to_s)
      next if text.blank?
    
      translation               = verse.translations.where(resource_content: resource).first_or_create
      translation.language      = resource.language
      translation.language_name = resource.language.name.downcase
      translation.resource_name = resource.name
      translation.foot_notes.delete_all
      translation.save
    
      if footnote.present?
        _footnote = translation.foot_notes.create(text: footnote.strip, language: resource.language, language_name: resource.language.name.downcase, resource_content: footnote_resource_content)
      
        text = ("#{text}" "<sup foot_note=#{_footnote.id}>1</sup>")
      end
    
      translation.text = text
      translation.save
    
      puts translation.id
    end
  end
  
  def parse_uzbek_sadiq(rows, resource)
    footnote_resource_content = ResourceContent.where({
                                                        author_id:        resource.author_id,
                                                        author_name:      resource.author.name,
                                                        resource_type:    "content",
                                                        sub_type:         "footnote",
                                                        name:             resource.name,
                                                        description:      "#{resource.name} footnotes",
                                                        cardinality_type: "1_ayah",
                                                        language_id:      resource.language.id,
                                                        language_name:    resource.language.name.downcase,
                                                      }).first_or_create
  
    rows.each do |row|
      verse = Verse.find_by_verse_key("#{row[1]}:#{row[2]}")
    
      text     = encode_and_clean_text(row[3].to_s).sub(/\d+./, '')
      footnote = encode_and_clean_text(row[4].to_s)
      next if text.blank?
    
      translation               = verse.translations.where(resource_content: resource).first_or_create
      translation.language      = resource.language
      translation.language_name = resource.language.name.downcase
      translation.resource_name = resource.name
      translation.foot_notes.delete_all
      translation.save
    
      if footnote.present?
        _footnote = translation.foot_notes.create(text: footnote.strip, language: resource.language, language_name: resource.language.name.downcase, resource_content: footnote_resource_content)
      
        text = ("#{text}" "<sup foot_note=#{_footnote.id}>1</sup>")
      end
    
      translation.text = text
      translation.save
    
      puts translation.id
    end
  end
  
  def parse_yoruba_mikail(rows, resource)
    footnote_resource_content = ResourceContent.where({
                                                        author_id:        resource.author_id,
                                                        author_name:      resource.author.name,
                                                        resource_type:    "content",
                                                        sub_type:         "footnote",
                                                        name:             resource.name,
                                                        description:      "#{resource.name} footnotes",
                                                        cardinality_type: "1_ayah",
                                                        language_id:      resource.language.id,
                                                        language_name:    resource.language.name.downcase,
                                                      }).first_or_create
  
    rows.each do |row|
      verse = Verse.find_by_verse_key("#{row[1]}:#{row[2]}")
    
      text     = encode_and_clean_text(row[3].to_s).sub(/\d+./, '')
      footnote = encode_and_clean_text(row[4].to_s)
      next if text.blank?
    
      translation               = verse.translations.where(resource_content: resource).first_or_create
      translation.language      = resource.language
      translation.language_name = resource.language.name.downcase
      translation.resource_name = resource.name
      translation.foot_notes.delete_all
      translation.save

      if footnote.present?
        _footnote = translation.foot_notes.create(text: footnote.strip, language: resource.language, language_name: resource.language.name.downcase, resource_content: footnote_resource_content)
      
        text = ("#{text}" "<sup foot_note=#{_footnote.id}>1</sup>")
      end
    
      translation.text = text
      translation.save
    
      puts translation.id
    end
  end
  
  def parse_urdu_junagarhi(rows, resource)
    footnote_resource_content = ResourceContent.where({
                                                        author_id:        resource.author_id,
                                                        author_name:      resource.author.name,
                                                        resource_type:    "content",
                                                        sub_type:         "footnote",
                                                        name:             resource.name,
                                                        description:      "#{resource.name} footnotes",
                                                        cardinality_type: "1_ayah",
                                                        language_id:      resource.language.id,
                                                        language_name:    resource.language.name.downcase,
                                                      }).first_or_create
    
    rows.each do |row|
      verse = Verse.find_by_verse_key("#{row[1]}:#{row[2]}")
      
      text     = encode_and_clean_text(row[3].to_s)
      footnote = encode_and_clean_text(row[4].to_s)
      next if text.blank?
      
      translation               = verse.translations.where(resource_content: resource).first_or_create
      translation.language      = resource.language
      translation.language_name = resource.language.name.downcase
      translation.resource_name = resource.name
      translation.foot_notes.delete_all
      translation.save

      footnote_ids = text.scan(/[\*]+/)
      footnotes    = footnote.split(/[\*]+/).select(&:present?)
      
      footnotes.present? && footnote_ids.each_with_index do |node, i|
        if footnotes[i]
          footnote = translation.foot_notes.create(text: footnotes[i].strip, language: resource.language, language_name: resource.language.name.downcase, resource_content: footnote_resource_content)
          
          text = text.sub("#{node}", "<sup foot_note=#{footnote.id}>#{i + 1}</sup>")
        end
      end
      
      if footnote_ids.blank? && footnotes.present?
        footnote = translation.foot_notes.create(text: footnotes.join("\n"), language: resource.language, language_name: resource.language.name.downcase, resource_content: footnote_resource_content)
        
        text = ("#{text}" "<sup foot_note=#{footnote.id}>1</sup>")
      end
      
      translation.text = text
      translation.save
      
      puts translation.id
    end
  end
  
  def parse_hindi_omari(rows, resource)
    footnote_resource_content = ResourceContent.where({
                                                        author_id:        resource.author_id,
                                                        author_name:      resource.author.name,
                                                        resource_type:    "content",
                                                        sub_type:         "footnote",
                                                        name:             resource.name,
                                                        description:      "#{resource.name} footnotes",
                                                        cardinality_type: "1_ayah",
                                                        language_id:      resource.language.id,
                                                        language_name:    resource.language.name.downcase,
                                                      }).first_or_create
    
    rows.each do |row|
      verse = Verse.find_by_verse_key("#{row[1]}:#{row[2]}")
      
      text     = encode_and_clean_text(row[3].to_s)
      footnote = encode_and_clean_text(row[4].to_s)
      
      translation               = verse.translations.where(resource_content: resource).first_or_create
      translation.language      = resource.language
      translation.language_name = resource.language.name.downcase
      translation.resource_name = resource.name
      translation.foot_notes.delete_all
      translation.save
      
      footnote_ids = text.scan(/\[\d+\]/)
      footnotes    = footnote.split(/\d+./).select(&:present?)
      
      footnote_ids.each_with_index do |node, i|
        footnote = translation.foot_notes.create(text: footnotes[i].to_s.strip, language: resource.language, language_name: resource.language.name.downcase, resource_content: footnote_resource_content)
        
        text = text.gsub("#{node}", "<sup foot_note=#{footnote.id}>#{i + 1}</sup>")
      end
      
      if footnote_ids.blank? && footnotes.present?
        footnote = translation.foot_notes.create(text: footnotes.join("\n"), language: resource.language, language_name: resource.language.name.downcase, resource_content: footnote_resource_content)
        
        text = ("#{text}" "<sup foot_note=#{footnote.id}>1</sup>")
      end
      
      translation.text = text
      translation.save
      
      puts translation.id
    end
  end
  
  def parse_hausa_gummi(rows, resource)
    footnote_resource_content = ResourceContent.where({
                                                        author_id:        resource.author_id,
                                                        author_name:      resource.author.name,
                                                        resource_type:    "content",
                                                        sub_type:         "footnote",
                                                        name:             resource.name,
                                                        description:      "#{resource.name} footnotes",
                                                        cardinality_type: "1_ayah",
                                                        language_id:      resource.language.id,
                                                        language_name:    resource.language.name.downcase,
                                                      }).first_or_create
    
    rows.each do |row|
      verse = Verse.find_by_verse_key("#{row[1]}:#{row[2]}")
      
      text     = encode_and_clean_text(row[3].to_s)
      footnote = encode_and_clean_text(row[4].to_s)
      next if text.blank?
      
      translation               = verse.translations.where(resource_content: resource).first_or_create
      translation.language      = resource.language
      translation.language_name = resource.language.name.downcase
      translation.resource_name = resource.name
      translation.foot_notes.delete_all
      translation.save
      
      footnote_ids = text.scan(/[\*]+/)
      footnotes    = footnote.split(/[\*]+/).select(&:present?)
      
      footnotes.present? && footnote_ids.each_with_index do |node, i|
        footnote = translation.foot_notes.create(text: footnotes[i].strip, language: resource.language, language_name: resource.language.name.downcase, resource_content: footnote_resource_content)
        
        text = text.gsub("#{node}", "<sup foot_note=#{footnote.id}>#{i + 1}</sup>")
      end
      
      
      if footnote_ids.blank? && footnotes.present?
        footnote = translation.foot_notes.create(text: footnotes.join("\n"), language: resource.language, language_name: resource.language.name.downcase, resource_content: footnote_resource_content)
        
        text = ("#{text}" "<sup foot_note=#{footnote.id}>1</sup>")
      end
      
      translation.text = text
      translation.save
      
      puts translation.id
    end
  end
  
  def parse_english_saheeh(rows, resource)
    footnote_resource_content = ResourceContent.where({
                                                        author_id:        resource.author_id,
                                                        author_name:      resource.author.name,
                                                        resource_type:    "content",
                                                        sub_type:         "footnote",
                                                        name:             resource.name,
                                                        description:      "#{resource.name} footnotes",
                                                        cardinality_type: "1_ayah",
                                                        language_id:      resource.language.id,
                                                        language_name:    resource.language.name.downcase,
                                                      }).first_or_create
    
    rows.each do |row|
      verse = Verse.find_by_verse_key("#{row[1]}:#{row[2]}")
      
      text     = encode_and_clean_text(row[3].to_s).sub(/\d+./, '')
      footnote = encode_and_clean_text(row[4].to_s)
      
      translation               = verse.translations.where(resource_content: resource).first_or_create
      translation.language      = resource.language
      translation.language_name = resource.language.name.downcase
      translation.resource_name = resource.name
      translation.foot_notes.delete_all
      translation.save
      
      
      if footnote.present?
        _footnote = translation.foot_notes.create(text: footnote, language: resource.language, language_name: resource.language.name.downcase, resource_content: footnote_resource_content)
        
        text = ("#{text}" "<sup foot_note=#{_footnote.id}>1</sup>")
      end
      
      translation.text = text
      translation.save
      
      puts translation.id
    end
  end
  
  def parse_english_hilali_khan(rows, resource)
    footnote_resource_content = ResourceContent.where({
                                                        author_id:        resource.author_id,
                                                        author_name:      resource.author.name,
                                                        resource_type:    "content",
                                                        sub_type:         "footnote",
                                                        name:             resource.name,
                                                        description:      "#{resource.name} footnotes",
                                                        cardinality_type: "1_ayah",
                                                        language_id:      resource.language.id,
                                                        language_name:    resource.language.name.downcase,
                                                      }).first_or_create
    
    rows.each do |row|
      verse = Verse.find_by_verse_key("#{row[1]}:#{row[2]}")
      
      text     = encode_and_clean_text(row[3].to_s).sub(/\d+./, '')
      footnote = encode_and_clean_text(row[4].to_s)
      
      translation               = verse.translations.where(resource_content: resource).first_or_create
      translation.language      = resource.language
      translation.language_name = resource.language.name.downcase
      translation.resource_name = resource.name
      translation.foot_notes.delete_all
      translation.save

      footnote_ids = text.scan(/\[\d+\]/)
      footnotes    = footnote.split(/\[\d+\]/).select(&:present?)
      
      footnote_ids.each_with_index do |node, i|
        footnote = translation.foot_notes.create(text: footnotes[i].to_s.strip, language: resource.language, language_name: resource.language.name.downcase, resource_content: footnote_resource_content)
        
        text = text.gsub("#{node}", "<sup foot_note=#{footnote.id}>#{i + 1}</sup>")
      end
      
      if footnote_ids.blank? && footnotes.present?
        footnote = translation.foot_notes.create(text: footnotes.join("\n"), language: resource.language, language_name: resource.language.name.downcase, resource_content: footnote_resource_content)
        
        text = ("#{text}" "<sup foot_note=#{footnote.id}>1</sup>")
      end
      
      translation.text = text
      translation.save
      
      puts translation.id
    end
  end
  
  def parse_albanian_nahi(rows, resource)
    footnote_resource_content = ResourceContent.where({
                                                        author_id:        resource.author_id,
                                                        author_name:      resource.author.name,
                                                        resource_type:    "content",
                                                        sub_type:         "footnote",
                                                        name:             resource.name,
                                                        description:      "#{resource.name} footnotes",
                                                        cardinality_type: "1_ayah",
                                                        language_id:      resource.language.id,
                                                        language_name:    resource.language.name.downcase,
                                                      }).first_or_create
    
    rows.each do |row|
      verse = Verse.find_by_verse_key("#{row[1]}:#{row[2]}")
      
      text     = encode_and_clean_text(row[3].to_s)
      footnote = encode_and_clean_text(row[4].to_s)
      
      if footnote.blank?
        parse_translation_and_footnote(verse, encode_and_clean_text(row[3].to_s), resource)
      else
        translation               = verse.translations.where(resource_content: resource).first_or_create
        translation.language      = resource.language
        translation.language_name = resource.language.name.downcase
        translation.resource_name = resource.name
        translation.foot_notes.delete_all
        translation.save

        footnote_ids = text.scan(/\[\d+\]/)
        footnotes    = footnote.split(/\[\d+\]/).select(&:present?)
        
        footnote_ids.each_with_index do |node, i|
          footnote = translation.foot_notes.create(text: footnotes[i].to_s.strip, language: resource.language, language_name: resource.language.name.downcase, resource_content: footnote_resource_content)
          
          text = text.gsub("#{node}", "<sup foot_note=#{footnote.id}>#{i + 1}</sup>")
        end
        translation.text = text
        translation.save
        
        puts translation.id
      end
    end
  end
  
  def parse_translation_and_footnote(verse, text, resource)
    translation               = verse.translations.where(resource_content: resource).first_or_create
    translation.language      = resource.language
    translation.language_name = resource.language.name.downcase
    translation.resource_name = resource.name
    
    translation.text = text.strip
    translation.save
    puts translation.id
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
  
  task import_quranenc_translations: :environment do
    PaperTrail.enabled = false
    
    require 'csv'
    data_source = DataSource.find_or_create_by(name: 'Quranenc', url: 'https://quranenc.com')
    
    resource_content_mapping = {
      albanian_nahi: { language: 187, author_name: 'Hasan Efendi Nahi' }, #88,
      amharic_sadiq: { language: 6, author_name: 'Sadiq and Sani' }, #87,
      assamese_rafeeq: { language: 10, author_name: 'Shaykh Rafeequl Islam Habibur-Rahman' },
      bosnian_korkut:  { language: 23, author_name: 'Besim Korkut' }, #25,
      chinese_makin:       { language: 185, author_name: 'Makin' },
      english_hilali_khan: { language: 38, author_name: 'Muhammad Taqi-ud-Din al-Hilali and Muhammad Muhsin Khan' },
      english_saheeh:      { language: 38, author_name: 'Saheeh International' }, #20,
      french_hameedullah: { language: 49, author_name: 'Muhammad Hamidullah' }, #31,
      hausa_gummi:      { language: 58, author_name: 'Abubakar Mahmood Jummi' },
      hindi_omari:      { language: 60, author_name: 'Maulana Azizul Haque al-Umari' },
      indonesian_sabiq: { language: 33, author_name: 'Sabiq' },
      japanese_meta:    { language: 76, author_name: 'Ryoichi Mita' }, #35,
      kazakh_altai:    { language: 82, author_name: 'Khalifah Altai' },
      khmer_cambodia:  { language: 84, author_name: 'Cambodian Muslim Community Development' },
      nepali_central:  { language: 116, author_name: 'Ahl Al-Hadith Central Society of Nepal' },
      oromo_ababor:    { language: 126, author_name: 'Ghali Apapur Apaghuna' },
      pashto_zakaria:  { language: 132, author_name: 'Zakaria' },
      portuguese_nasr: { language: 133, author_name: 'Nasr' },
      turkish_shaban:  { language: 167, author_name: 'Shaban Britch' },
      turkish_shahin:  { language: 167, author_name: 'Muslim Shahin' },
      urdu_junagarhi:  { language: 174, author_name: 'مولانا محمد جوناگڑھی' }, #54,
      uzbek_sadiq: { language: 175, author_name: 'Muhammad Sodik Muhammad Yusuf' }, #55,
      uzbek_mansour: { language: 175, author_name: 'Alauddin Mansour' },
      yoruba_mikail: { language: 183, author_name: 'Shaykh Abu Rahimah Mikael Aykyuni' }
    }
    
    footnotes = ['albanian_nahi', 'english_hilali_khan', 'english_saheeh', 'hausa_gummi', 'hindi_omari', 'indonesian_sabiq', 'portuguese_nasr',
                 'urdu_junagarhi', 'uzbek_mansour', 'uzbek_sadiq', 'yoruba_mikail'
    ]

    tafsirs = ['arabic_mokhtasar']
    
    Dir['csv/csv/*'].each do |file|
      translation_name = file.split('/').last.split('.').first

      if resource_content_mapping[translation_name.to_sym].blank?
        next
      end

      language = Language.find(resource_content_mapping[translation_name.to_sym][:language])
      author   = Author.find_or_create_by(name: resource_content_mapping[translation_name.to_sym][:author_name])

      resource =  ResourceContent.find_or_create_by(
                     language:         language,
                     data_source:      data_source,
                     author_name:      author.name,
                     author:           author,
                     language_name:    language.name.downcase,
                     cardinality_type: ResourceContent::CardinalityType::OneVerse,
                     sub_type:         ResourceContent::SubType::Translation,
                     resource_type:    ResourceContent::ResourceType::Content,
                     )

      resource.update_attribute :name, author.name

      rows = CSV.open(file).read
      if footnotes.include?(translation_name)
        send "parse_#{translation_name}", rows[1..rows.length], resource
      else
        rows[1..rows.length].each do |row|
          verse = Verse.find_by_verse_key("#{row[1]}:#{row[2]}")
          
          parse_translation_and_footnote(verse, encode_and_clean_text(row[3].to_s), resource)
        end
      end
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
  
  def process_foot_note_text(foot_note_node)
    foot_note_node.search("span").each do |node|
      if node.attr('class').to_s.strip == 'c15'
        node.name = "sup"
        node.remove_attribute("class")
      end
    end
    
    # remove links
    foot_note_node.search("a").remove
    
    white_list_sanitizer = Rails::Html::WhiteListSanitizer.new
    
    white_list_sanitizer.sanitize(foot_note_node.to_s.strip, tags: %w(div sup p ol ul li), attributes: []).gsub(/[\r\n]+/, "<br/>")
  end
  
  task import_musfata_khitab_with_footnote: :environment do
    PaperTrail.enabled = false
    
    author   = Author.where(name: 'Dr. Mustafa Khattab').first_or_create
    language = Language.find_by_name 'English'
    data_source = DataSource.where(name: 'Quran.com').first_or_create
    
    url = "https://raw.githubusercontent.com/naveed-ahmad/Quran-text/master/cleanquran.html"
    
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
    
    
    docs.search('ol .c0').each_with_index do |verse_node, v_index|
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
