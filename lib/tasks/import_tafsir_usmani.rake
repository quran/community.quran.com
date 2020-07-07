namespace :import_tafisr_usmani do
  DEBUG = true

  def prepare_foot_note_text(dom, texts = [], index)
    if 0 == dom.children.length || 'arabic' == dom.attributes['id']&.value
      text = if 'span' == dom.name
               if 'arabic' == dom.attributes['id'].value
                 "<span class=indopak>#{dom.text}</span>"
               else
                 dom.text.strip
               end
             else
               dom.text.strip
             end

      text = text.gsub('|iValues|', '')
      texts.push(text) if text.length > 0
      return texts
    else
      dom.children.each do |child_dom|
        prepare_foot_note_text(child_dom, texts, index)

        if 'br' == child_dom.name
          texts[texts.length - 1] = "<strong class=h>#{texts[texts.length - 1]}</strong>"
        end
      end
      texts
    end
  end

  task run: :environment do
    FOOT_NOTE_REG = /\[[۰۱۲۳۴۵۶۷۸۹]*\]/ #/\[(\d)*\]/

    author_name = "Shaykh al-Hind Mahmud al-Hasan"
    localized_name = "مولانا فتح محمد جلندھری"
    language = Language.find_by_iso_code('ur')
    data_source = DataSource.where(name: 'http://www.noorehidayat.org/').first_or_create

    author = Author.where(name: author_name).first_or_create
    if localized_name
      author.translated_names.where(language: language).first_or_create(name: localized_name)
    end

    resource_content = ResourceContent.where(data_source: data_source, cardinality_type: ResourceContent::CardinalityType::OneVerse, sub_type: ResourceContent::SubType::Translation, resource_type: ResourceContent::ResourceType::Content, language: language, author: author).first_or_create
    resource_content.author_name = author.name
    resource_content.name = "Shaykh al-Hind Mahmud al-Hasan(Tafsir e Usmani)"
    resource_content.language_name = language.name.downcase
    resource_content.approved = false  #varify and approve after importing
    resource_content.slug = "tafsir-e-usmani"
    resource_content.priority = 3
    resource_content.save

    footnote_resource_content = ResourceContent.where({
                                                          author_id: author.id,
                                                          author_name: author.name,
                                                          resource_type: "content",
                                                          sub_type: "footnote",
                                                          name: author.name,
                                                          description: "#{author.name} - Tafsir e Usmani",
                                                          cardinality_type: "1_ayah",
                                                          language_id: language.id,
                                                          language_name: "urdu",
                                                          slug: 'tafsir-e-usmani-footnote',
                                                          data_source: data_source
                                                      }).first_or_create
    Verse.order("verse_index ASC").each do |v|
      translation = v.translations.where(resource_content_id: resource_content.id).first_or_create
      translation.save(validate: false)
      puts translation.id

      url = "http://www.noorehidayat.org/index.php?p=surah&s=#{v.chapter_id}&t=0&a=#{v.verse_number}&c=2"
      text = "<div>#{open(url).read}</div>"
      docs = Nokogiri::HTML(text)

      translation_text = docs.search('#trans')[0].content.to_s.strip

      foot_note_index = 1

      translation.language = language
      translation.language_name = language.name.downcase
      translation.language_name = language.name.downcase
      translation.resource_name = resource_content.name
      translation.priority = resource_content.priority

      translation.save(validate: false)
      translation.foot_notes.delete_all

      translation_text.gsub!(FOOT_NOTE_REG) do
        i = foot_note_index
        foot_note_index += 1

        if (dom = docs.search('#trans')[i])
          footnote_text = prepare_foot_note_text(dom, [], 0)

          if (footnote_text = footnote_text.join('')).length > 0
            footnote_text.gsub!(FOOT_NOTE_REG, '')

            footnote = translation.foot_notes.create(text: footnote_text, language: language, language_name: language.name.downcase, resource_content: footnote_resource_content)

            "<sup foot_note=#{footnote.id}>#{i}</sup>"
          else
            ''
          end
        else
          ''
        end
      end

      translation.text = translation_text
      translation.save(validate: false)
      puts v.verse_key
    end
  end
end


