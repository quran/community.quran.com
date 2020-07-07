namespace :parse_brdidge_translation do
  $parent_doc = nil
  $RUK = true
  $foot_note_counter = 0
  $white_space = " "
  $qirat_class = 'c10'
  # 10
  $ayah_container_key = ".c17"
  $sup_class = "c0"
  $highlight_class = "c5" # c11 and c3
  $ayah_number_class = 'c4' # c2 and c3
  $italic = 'c1'
  $foot_note_sup_class = 'c11'
  $qirat_foot_note_higlight_class = 'c9'

  task run: :environment do
    PaperTrail.enabled = false

    class FootNote < QuranApiRecord
      attr_writer :texts

      def add_text(text)
        @texts ||= []
        @texts << text
      end

      def full_text
        @texts ||= []

        @texts.join ''
      end
    end

    class Translation < QuranApiRecord
      attr_writer :texts, :html

      def add_text(text)
        @texts ||= []
        @texts << text
      end

      def add_html(_html)
        @html ||= []

        @html << _html
      end

      def full_text
        @texts.join ''
      end

      def full_html
        @html.join ''
      end
    end

    def parse_footnote(dom, footnote)
      if dom.children.count == 1
        if dom.name != 'a'
          text = dom.children.first.text

          if text[0] == $white_space
            text = text.gsub(/\u00A0/, '')
          end

          if dom.attr('class').to_s.include?($qirat_class)
            text = "<b class=h>Qira’at: </b>"
          end

          if dom.attr('class').to_s.include?($qirat_foot_note_higlight_class)
            text = "<span class=h>#{text}</span>"
          end

          if dom.attr('class').to_s.include?($foot_note_sup_class)
            text = "<sup>#{text} </sup>"
          end

          footnote.add_text(text)
        end
      else
        dom.children.each do |_dom|
          parse_footnote(_dom, footnote)
        end
      end

      footnote
    end

    def parse_dom(dom, translation = nil, resource_content, footnote_resource_content)
      if dom.children.count == 1 #&& dom.children.first.class == Nokogiri::XML::Text
        #
        # we've reached to leaf node. Check if its ayah number or text
        #

        text = dom.children.first.text.to_s.gsub("&nbsp;", ' ')
        html = dom.children.to_s

        if dom.attr('class').to_s.include?($sup_class)
          # superscripts
          text = text.gsub(/\[\d*\]/, '').strip

          if text.present?
            text = "<a class='sup'><sup>#{text.strip} </sup></a>"
          end
        end

        if dom.attr('class').to_s.include?($italic)
          if text.present?
            text = "<i class=s>#{text.gsub("&nbsp;", '').strip}</i> "
          end
        end

        if dom.attr('class').to_s.include?($highlight_class)
          # red highlighted text
          text = text.gsub(/\[\d*\]/, ' ').strip
          if text.present?
            text = "<span class=h>#{text.gsub("&nbsp;", ' ').strip}</span>"
          end
        end

        if dom.children.first.attr('href').present?
          id = dom.children.first.attr('href')
          parent_dom = $parent_doc.search(id).first.ancestors('div').first

          foot_note = translation.foot_notes.create(text: "", language: footnote_resource_content.language, language_name: footnote_resource_content.language.name.downcase, resource_content: footnote_resource_content)
          parse_footnote(parent_dom, foot_note)

          foot_note_text = foot_note.full_text.gsub(/\[\d*\]/, '').gsub("&nbsp;", ' ').strip

          if foot_note_text.present?
            if foot_note_text[0] == $white_space
              foot_note_text = foot_note_text.gsub(/\u00A0/, '')
            end

            foot_note.text = foot_note_text
            foot_note.save
            text = "<a class=f><sup foot_note=#{foot_note.id}>#{$foot_note_counter += 1}</sup></a>"
          else
            foot_note.delete
          end
        end

        if text.to_i > 0 || dom.attr('class').to_s.strip.include?($ayah_number_class)
          # ayah number
          ayah_number = text.gsub("&nbsp;", '').gsub(/\D/, '')
          key = "#{$chapter}:#{ayah_number}"

          if !translation
            verse = Verse.find_by_verse_key(key)
            translation = verse.translations.where(resource_content: resource_content).first_or_create
            translation.language =  resource_content.language
            translation.language_name =  resource_content.language.name.downcase
            translation.priority = 5
            translation.resource_name = resource_content.name


            puts "Init #{key} #{translation.id}"

            translation.save
          else
            # save previous ayah
            # and processed to next ayah

            translation_text = translation.full_text
            if translation_text[0] == $white_space
              translation_text = translation_text.gsub(/\u00A0/, '')
            end

            translation.text = translation_text.strip

            translation.save

            verse = Verse.find_by_verse_key(key)
            translation = verse.translations.where(resource_content: resource_content).first_or_create
            translation.language =  resource_content.language
            translation.language_name =  resource_content.language.name.downcase
            translation.resource_name = resource_content.name

            translation.priority = 5
            translation.save
            puts translation.id

            $foot_note_counter = 0
          end
        else
          if (_t = text.gsub("&nbsp;", ' ')).presence
            translation.add_text(_t)
            translation.add_html(html)
          end
        end
      else
        dom.children.each do |_dom|
          parse_dom(_dom, translation, resource_content, footnote_resource_content)
        end
      end

      translation
    end

    author = Author.where(name: 'Fadel Soliman', url: "https://bridges-foundation.org").first_or_create
    language = Language.find_by_name 'English'

    source = DataSource.where(name: 'Bridges’ Foundation', url: "https://bridges-foundation.org").first_or_create

    resource_content = ResourceContent.where({
                                                 author_id: author.id,
                                                 author_name: author.name,
                                                 resource_type: "content",
                                                 sub_type: "translation",
                                                 name: "Bridges’ Translation",
                                                 description: "Bridges’ Translation of the Ten Qira’at of the Noble Qur’an",
                                                 cardinality_type: "1_ayah",
                                                 language_id: language.id,
                                                 language_name: "english",
                                                 priority: 2,
                                                 data_source: source,
                                                 slug: 'bridges-translation'}).first_or_create

    footnote_resource_content = ResourceContent.where({
                                                          author_id: author.id,
                                                          author_name: author.name,
                                                          resource_type: "content",
                                                          sub_type: "footnote",
                                                          name: "Bridges’ translation footnotes",
                                                          description: "Bridges’ Translation of the Ten Qira’at of the Noble Qur’an",
                                                          cardinality_type: "1_ayah",
                                                          language_id: language.id,
                                                          language_name: "english",
                                                          data_source: source,
                                                          slug: 'bridges-translations-footnote'}).first_or_create

    Translation.where(resource_content: resource_content).delete_all
    FootNote.where(resource_content: footnote_resource_content).delete_all

    parent_doc = if Rails.env.development?
                   File.read("data/QuranBridge.html")
                 else
                   open("https://raw.githubusercontent.com/naveed-ahmad/the_bridges_quran_api/master/data/QuranBridge.html").read
                 end

    $parent_doc = Nokogiri::HTML.parse(parent_doc)

    1.upto(114) do |c|
      $chapter = c
      $foot_note_counter = 0

      url = "https://raw.githubusercontent.com/naveed-ahmad/the_bridges_quran_api/master/data/chapters/#{c}.html"

      text = if Rails.env.development?
               File.read("data/chapters/#{$chapter}.html")
             else
               open(url).read
             end

      text = "<div>#{text}</div>"

      $doc = Nokogiri::HTML.parse(text)
      translation = nil

      $doc.search($ayah_container_key).each do |group|
        group.children.each do |parent_dom|
          translation = parse_dom(parent_dom, translation, resource_content, footnote_resource_content)
        end
      end

      translation_text = translation.full_text
      if translation_text[0] == $white_space
        translation_text = translation_text.gsub(/\u00A0/, '')
      end

      translation.text = translation_text.strip
      translation.save
    end
  end
end