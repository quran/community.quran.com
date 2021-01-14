namespace :import_isa_gracia do
  
  task run: :environment do
    VERSE_START_REG = /\d+(\.|\s)*/
    PaperTrail.enabled = false
    url = "https://gist.githubusercontent.com/danish2210/c396fc899244bbe57cae7097fbfad7bd/raw/dae7ee7f767c1a216a2c2cdcded21fcbbc669ac6/isa_gracia_translation"
    language = Language.find_by_iso_code('es')
    footnote_resource_content_id = 197
    resource_content_id = 83
    resource_name = ResourceContent.find(83).name
    Translation.where(resource_content_id: resource_content_id).delete_all
    FootNote.where(resource_content_id: footnote_resource_content_id).delete_all
    
    parsed_html = Nokogiri.parse URI.open(url).read
    chapter_number = 0
    chapter = nil
    parsed_html.css(".c2").each_with_index do |p_tag, p_index|
      next if p_tag.children.first.attributes["class"].nil?
      next if p_tag.children.count == 1 && p_tag.children.first.attributes["class"].value == "c16 c14 c11 c17" # reject chapter numbers
      next if !p_tag.text.present?
      klasses = p_tag.children.first.attributes["class"].value.strip
      if klasses  == "c14 c22 c11" || klasses == "c14 c39 c11" || klasses == "c16 c14 c22 c11" || klasses ==  "c13 c22 c11" || klasses ==  "c14 c35 c11" || klasses  == "c14 c11 c22"# chapter_name
        chapter_number += 1
        chapter = Chapter.find_by_chapter_number(chapter_number)
        puts "chapter #{chapter_number}"
        puts chapter.name_simple
      else
        verse_number = p_tag.text.match(VERSE_START_REG)[0].tr!('.', '').strip.to_i rescue nil
        next if verse_number.nil?
        puts verse_number
        verse = chapter.verses.find_by_verse_number(verse_number)
        foot_note_counter = 0
        foot_note_ids = []
        text = p_tag.children.collect do |node|
          if node.name == "sup"
            id = node.children.first.attributes["href"].value
            foot_note_text = parsed_html.css(id).first.parent.children.each_with_index.collect do |f_node,index|
              index > 1 ? f_node.text : nil
            end.compact.join
            return nil if foot_note_text.nil?
            foot_note = FootNote.new(text: foot_note_text,language: language, language_name: language.name.downcase, resource_content_id: footnote_resource_content_id)
            foot_note.save(validate: false)
            foot_note_ids << foot_note.id
            "<sup foot_note=#{foot_note.id}>#{foot_note_counter += 1}</sup>"
          else
            node.text
          end
        end.compact.join.gsub(/^[0-9\.\s\-]+/, "")
        
        translation = verse.translations.where(resource_content_id: resource_content_id).first_or_create
        translation.language = language
        translation.text = text
        translation.resource_name = resource_name
        translation.save(validate: false)
        FootNote.where(id: foot_note_ids).update_all(translation_id: translation.id)
      end
    end
  end
end