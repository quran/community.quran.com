namespace :import_maududi_tafseer do
  
  task run: :environment do
    PaperTrail.enabled = false
    
    #author_name = "Abul Ala Maududi"
    language = Language.find_by_iso_code('en')
    base_uri = "https://islamicstudies.info/tafheem.php"
    resource_content = ResourceContent.find(95) #Tafheem-ul-Quran - Abul Ala Maududi
    footnote_resource_content = ResourceContent.find 96
    #info_resource_content = ResourceContent.find 95
  
    Translation.where(resource_content_id: resource_content.id).delete_all
    FootNote.where(resource_content_id: footnote_resource_content.id).delete_all

    browser = ::Watir::Browser.new :chrome, headless: true
    
    1.upto(114) do |index|
      verse_number = 1
      query = "?sura=#{index}&verse=2"
      url = base_uri + query
      puts query
      chapter = Chapter.find_by_chapter_number(index)
      page, next_page_query = navigate url, browser
      verse_number = parse_and_save page, chapter, language, resource_content, footnote_resource_content, verse_number
      while query != next_page_query
        url = base_uri + next_page_query
        query = next_page_query
        page, next_page_query = navigate url, browser
        verse_number = parse_and_save page, chapter, language, resource_content, footnote_resource_content, verse_number
        puts query
      end
    end
    browser.close
  ensure
    browser.close
  end
  
  def navigate url, browser
    browser.goto url
    page = Nokogiri::HTML.parse(browser.html)

    # docs = Nokogiri::HTML::DocumentFragment.parse(body)

    next_page_query = page.css("#next").children.css("a").first.attributes["href"].value
    return page, next_page_query
  end
  
  def parse_and_save page, chapter, language, resource_content, footnote_resource_content, verse_number
    page.css("#tr3").children.css(".v").each do |verse_data|
      verse = chapter.verses.find_by_verse_number(verse_number)
      break if verse.blank?
      foot_note_counter = 0
      foot_note_ids = []
      text = verse_data.css(".en").children.collect do |node|
        if node.name == "sup"
          #bug 16:56 no sup there
          tafseer_text = verse_data.css(".nt").children.css("p")[foot_note_counter].text.gsub("\n\t","").gsub(/^[0-9\.\s\-]+/, "") rescue nil
          return nil if tafseer_text.nil?
          foot_note = FootNote.new(text: tafseer_text,language: language, language_name: language.name.downcase, resource_content: footnote_resource_content)
          foot_note.save(validate: false)
          foot_note_ids << foot_note.id
          "<sup foot_note=#{foot_note.id}>#{foot_note_counter += 1}</sup>"
        else
          node.to_s
        end
      end.compact.join.gsub(/^\((\d+\:\d+)\)/, '').strip.gsub("\n\t","")
      translation = verse.translations.where(resource_content_id: resource_content.id).first_or_create
      translation.text = text
      translation.save(validate: false)
      FootNote.where(id: foot_note_ids).update_all(translation_id: translation.id)
      verse_number += 1
    end
    verse_number
  end
  
end