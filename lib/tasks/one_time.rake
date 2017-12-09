namespace :one_time do
  
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
    
    text= if Rails.env.development?
            File.open("lib/data/transaction.docx.html").read
          else
            open(url).read
          end
    
    docs = Nokogiri.parse(text)
    
    docs.search("body > .c1").each_with_index do |verse_node, v_index|
      text = verse_node.text.to_s.split("|")[2].to_s.strip
      
      if verse = Verse.find_by_verse_index(v_index+1)
        translation = verse.translations.where(resource_content: resource_content).first_or_create
        translation.foot_notes.delete_all
        
        verse_node.search("a").each_with_index do |footnote_node, f_i|
          footnote_id   = footnote_node.attributes['href'].value
          number        = footnote_id.scan(/\d/).join('')
          # footnote_text = docs.search(footnote_id).first.parent.search('span').text.strip
          footnote_text = docs.search(footnote_id).first.parent.search('.c4').text.strip
          
          footnote = translation.foot_notes.create(text: footnote_text, language: language, language_name: language.name.downcase, resource_content: footnote_resource_content)
          
          text = text.gsub!("[#{number}]#{number}", "<sup foot_note=#{footnote.id}>#{f_i+1}</sup>")
        end
        
        translation.text          = text.strip
        translation.language      =language
        translation.language_name =language.name.downcase
        translation.resource_name = resource_content.name
        translation.save
        puts "update translation #{translation.id}"
      end
    end
  end
  
  def process_foot_note_text(foot_note_node)
    foot_note_node.search("span").each do |node|
      if node.attr('class').to_s.strip == 'c15'
        node.name= "sup"
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
    
    url = "https://raw.githubusercontent.com/naveed-ahmad/Quran-text/master/cleanquran.html"

    text= if Rails.env.development?
           File.open("lib/data/cleanquran.html").read
          else
            open(url).read
          end
    
    docs = Nokogiri.parse(text)
    
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
                                               slug:             'clearquran-with-tafsir' }).first_or_create
    
    footnote_resource_content = ResourceContent.where({
                                                        author_id:        author.id,
                                                        author_name:      author.name,
                                                        resource_type:    "content",
                                                        sub_type:         "footnote",
                                                        name:             'Dr. Mustafa Khattab, The Clear Quran(With Tafsir)',
                                                        description:      'Dr. Mustafa Khattab, The Clear Quran(With Tafsir)',
                                                        cardinality_type: "1_ayah",
                                                        language_id:      language.id,
                                                        language_name:    "english",
                                                        slug:             'clearquran-with-tafsir-footnote' }).first_or_create
    
    
    docs.search('ol .c0').each_with_index do |verse_node, v_index|
      text        = verse_node.text.strip
      verse       = Verse.find_by_verse_index(v_index+1)
      translation = verse.translations.where(resource_content: resource_content).first_or_create
      translation.foot_notes.delete_all
      
      verse_node.search("a").each_with_index do |footnote_node, f_i|
        footnote_id   = footnote_node.attributes['href'].value
        number        = footnote_id.scan(/\d/).join('')
        
        footnote_text = process_foot_note_text(docs.search(footnote_id).first.parent.parent)
        footnote      = translation.foot_notes.create(text: footnote_text, language: language, language_name: 'english', resource_content: footnote_resource_content)
        
        text = text.gsub!("[#{number}]", "<sup foot_note=#{footnote.id}>#{f_i+1}</sup>")
      end
      
      translation.text          = text.strip
      translation.language      =language
      translation.language_name ='english'
      translation.resource_name = resource_content.name
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
          
          if join_trans && final_words[i+1+word_joined]
            #urdu_trans = "#{urdu_trans} #{urdu}"
            next_word      = final_words[i+1+word_joined]
            arabic_n, urdu = next_word.split(':').map(&:strip!)
            urdu_trans     = nil
          else
            if text_madani.include?(arabic) && text_madani != arabic && final_words[i+1+word_joined]
              #join translation with next word
              next_word           = final_words[i+1+word_joined]
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
          
          if join_trans && final_words[i+1]
            #urdu_trans = "#{urdu_trans} #{urdu}"
            next_word      = final_words[i+1]
            arabic_n, urdu = next_word.split(':').map(&:strip!)
            urdu_trans     = nil
          else
            if text_madani.include?(arabic) && text_madani != arabic && final_words[i+1]
              #join translation with next word
              next_word           = final_words[i+1]
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
  