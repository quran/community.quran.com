namespace :roberto_piccardo do
  task run: :environment do
    SURAH_NAME_REGEXP = Regexp.new('\([^)]*\)')
    ActiveRecord::Base.logger = nil
    VERSE_START_REG = /\d+(\.|\s)*/
    PaperTrail.enabled = false

    require 'mechanize'
    url = "http://ilcorano.net/il-sacro-corano/1-surat-al-fatiha/"
    language = Language.find_by_iso_code('it')

    author_name = "Hamza Roberto Piccardo"
    data_source = DataSource.where(name: 'http://ilcorano.net/').first_or_create
    author = Author.where(name: author_name).first_or_create

    resource_content = ResourceContent.where(data_source: data_source, cardinality_type: ResourceContent::CardinalityType::OneVerse, sub_type: ResourceContent::SubType::Translation, resource_type: ResourceContent::ResourceType::Content, language: language, author: author).first_or_create
    resource_content.author_name = author.name
    resource_content.name = author_name
    resource_content.language_name = language.name.downcase
    resource_content.approved = true #varify and approve after importing
    resource_content.slug = "hamza-roberto-piccardo"
    resource_content.priority = 4
    resource_content.save

    footnote_resource_content = ResourceContent.where({
                                                          author_id: author.id,
                                                          author_name: author.name,
                                                          resource_type: "content",
                                                          sub_type: "footnote",
                                                          name: author.name,
                                                          cardinality_type: "1_ayah",
                                                          language_id: language.id,
                                                          language_name: language.name.downcase,
                                                          slug: 'hamza-roberto-piccardo-footnote',
                                                          data_source: data_source
                                                      }).first_or_create

    info_resource_content = ResourceContent.where({
                                                      author_id: author.id,
                                                      author_name: author.name,
                                                      resource_type: "content",
                                                      sub_type: "info",
                                                      name: author.name,
                                                      cardinality_type: "1_chapter",
                                                      language_id: language.id,
                                                      language_name: language.name.downcase,
                                                      slug: 'hamza-roberto-piccardo-info',
                                                      data_source: data_source
                                                  }).first_or_create

    Translation.where(resource_content_id: resource_content.id).delete_all
    FootNote.where(resource_content_id: footnote_resource_content.id).delete_all

    agent = Mechanize.new
    #body = agent.get(url)

    # surah_urls = body.search("ul.children li.page_item a").map do |link|
    #  surah_url = link.attr("href")
    #  if /\d+-/ =~ surah_url
    #    surah_url
    #  end
    # end.compact

    surah_urls = ["https://ilcorano.net/il-sacro-corano/1-surat-al-fatiha/",
                  "https://ilcorano.net/il-sacro-corano/2-surat-al-baqara/",
                  "https://ilcorano.net/il-sacro-corano/3-surat-al-imran/",
                  "https://ilcorano.net/il-sacro-corano/4-surat-an-nisa/",
                  "https://ilcorano.net/il-sacro-corano/5-surat-al-maida/",
                  "https://ilcorano.net/il-sacro-corano/6-surat-al-anam/",
                  "https://ilcorano.net/il-sacro-corano/7-surat-al-araf/",
                  "https://ilcorano.net/il-sacro-corano/8-surat-al-anfal/",
                  "https://ilcorano.net/il-sacro-corano/9-surat-at-tawba/",
                  "https://ilcorano.net/il-sacro-corano/10-surat-yunus/",
                  "https://ilcorano.net/il-sacro-corano/11-surat-hud/",
                  "https://ilcorano.net/il-sacro-corano/12-sura-yusuf/",
                  "https://ilcorano.net/il-sacro-corano/13-sura-ar-rad/",
                  "https://ilcorano.net/il-sacro-corano/14-sura-ibrahim/",
                  "https://ilcorano.net/il-sacro-corano/15-sura-al-hijr/",
                  "https://ilcorano.net/il-sacro-corano/16-sura-an-nahl/",
                  "https://ilcorano.net/il-sacro-corano/17-sura-al-isra/",
                  "https://ilcorano.net/il-sacro-corano/18-sura-al-kahf/",
                  "https://ilcorano.net/il-sacro-corano/19-sura-maryam/",
                  "https://ilcorano.net/il-sacro-corano/20-surat-ta-ha/",
                  "https://ilcorano.net/il-sacro-corano/21-surat-al-anbiya/",
                  "https://ilcorano.net/il-sacro-corano/22-surat-al-hajj/",
                  "https://ilcorano.net/il-sacro-corano/23-surat-al-muminun/",
                  "https://ilcorano.net/il-sacro-corano/24-surat-an-nur/",
                  "https://ilcorano.net/il-sacro-corano/25-sura-al-furqan/",
                  "https://ilcorano.net/il-sacro-corano/26-surat-ash-shuara/",
                  "https://ilcorano.net/il-sacro-corano/27-surat-an-naml/",
                  "https://ilcorano.net/il-sacro-corano/28-surat-al-qasas/",
                  "https://ilcorano.net/il-sacro-corano/29-sura-xxix-al-ankabut/",
                  "https://ilcorano.net/il-sacro-corano/30-sura-ar-rum/",
                  "https://ilcorano.net/il-sacro-corano/31-sura-luqman/",
                  "https://ilcorano.net/il-sacro-corano/32-sura-as-sajda/",
                  "https://ilcorano.net/il-sacro-corano/33-sura-al-ahzab/",
                  "https://ilcorano.net/il-sacro-corano/34-sura-saba/",
                  "https://ilcorano.net/il-sacro-corano/35-sura-fatir/",
                  "https://ilcorano.net/il-sacro-corano/36-sura-ya-sin/",
                  "https://ilcorano.net/il-sacro-corano/37-sura-as-saffat/",
                  "https://ilcorano.net/il-sacro-corano/38-sura-sad/",
                  "https://ilcorano.net/il-sacro-corano/39-sura-az-zumar/",
                  "https://ilcorano.net/il-sacro-corano/40-sura-al-ghafir/",
                  "https://ilcorano.net/il-sacro-corano/41-sura-fussilat/",
                  "https://ilcorano.net/il-sacro-corano/42-sura-ash-shura/",
                  "https://ilcorano.net/il-sacro-corano/43-sura-az-zukhruf/",
                  "https://ilcorano.net/il-sacro-corano/44-sura-ad-dukhan/",
                  "https://ilcorano.net/il-sacro-corano/45-sura-al-jathiya/",
                  "https://ilcorano.net/il-sacro-corano/46-sura-al-ahqaf/",
                  "https://ilcorano.net/il-sacro-corano/47-sura-muhammad/",
                  "https://ilcorano.net/il-sacro-corano/48-sura-al-fath/",
                  "https://ilcorano.net/il-sacro-corano/49-sura-al-hujurat/",
                  "https://ilcorano.net/il-sacro-corano/50-sura-qaf/",
                  "https://ilcorano.net/il-sacro-corano/51-sura-adh-dhariyat/",
                  "https://ilcorano.net/il-sacro-corano/52-sura-at-tur/",
                  "https://ilcorano.net/il-sacro-corano/53-sura-an-najm/",
                  "https://ilcorano.net/il-sacro-corano/54-sura-al-qamar/",
                  "https://ilcorano.net/il-sacro-corano/55-sura-ar-rahman/",
                  "https://ilcorano.net/il-sacro-corano/56-sura-al-waqia/",
                  "https://ilcorano.net/il-sacro-corano/57-sura-al-hadid/",
                  "https://ilcorano.net/il-sacro-corano/58-sura-al-mujadila/",
                  "https://ilcorano.net/il-sacro-corano/59-sura-al-hashr/",
                  "https://ilcorano.net/il-sacro-corano/60-sura-al-mumtahana/",
                  "https://ilcorano.net/il-sacro-corano/61-sura-a%e1%b9%a3-%e1%b9%a3aff/",
                  "https://ilcorano.net/il-sacro-corano/62-sura-al-jumua/",
                  "https://ilcorano.net/il-sacro-corano/63-sura-al-munafiqun/",
                  "https://ilcorano.net/il-sacro-corano/64-sura-at-taghabun/",
                  "https://ilcorano.net/il-sacro-corano/65-sura-at-talaq-il-divorzio/",
                  "https://ilcorano.net/il-sacro-corano/66-sura-at-tahrim-linterdizione/",
                  "https://ilcorano.net/il-sacro-corano/67-sura-al-mulk-la-sovranita/",
                  "https://ilcorano.net/il-sacro-corano/68-sura-al-qalam-il-calamo/",
                  "https://ilcorano.net/il-sacro-corano/69-sura-al-haqqah-linevitabile/",
                  "https://ilcorano.net/il-sacro-corano/70-sura-al-maarij-le-vie-dellascesa/",
                  "https://ilcorano.net/il-sacro-corano/71-sura-nuh-noe/",
                  "https://ilcorano.net/il-sacro-corano/72-sura-al-jinn-i-demoni/",
                  "https://ilcorano.net/il-sacro-corano/73-sura-al-muzzammil-lavvolto/",
                  "https://ilcorano.net/il-sacro-corano/74-sura-al-muddaththir-l-avvolto-nel-mantello/",
                  "https://ilcorano.net/il-sacro-corano/75-sura-al-qiyama-la-resurrezione/",
                  "https://ilcorano.net/il-sacro-corano/76-sura-al-insan-luomo/",
                  "https://ilcorano.net/il-sacro-corano/77-sura-al-mursalat-le-inviate/",
                  "https://ilcorano.net/il-sacro-corano/78-sura-an-naba-lannuncio/",
                  "https://ilcorano.net/il-sacro-corano/79-sura-an-naziat-le-strappanti-violente/",
                  "https://ilcorano.net/il-sacro-corano/80-sura-abasa-si-acciglio/",
                  "https://ilcorano.net/il-sacro-corano/81-sura-at-takwir-loscuramento/",
                  "https://ilcorano.net/il-sacro-corano/82-sura-al-infitar-lo-squarciarsi/",
                  "https://ilcorano.net/il-sacro-corano/83-sura-al-mutaffifin-i-frodatori/",
                  "https://ilcorano.net/il-sacro-corano/84-sura-al-inshiqaq-la-fenditura/",
                  "https://ilcorano.net/il-sacro-corano/85-sura-al-buruj-le-costellazioni/",
                  "https://ilcorano.net/il-sacro-corano/86-suraat-tariq-lastro-notturno/",
                  "https://ilcorano.net/il-sacro-corano/87-sura-al-ala-laltissimo/",
                  "https://ilcorano.net/il-sacro-corano/88-sura-al-ghashiya-l-avvolgente/",
                  "https://ilcorano.net/il-sacro-corano/89-sura-al-fajr-lalba/",
                  "https://ilcorano.net/il-sacro-corano/90-sura-al-balad-la-contrada/",
                  "https://ilcorano.net/il-sacro-corano/91-sura-ash-shams-il-sole/",
                  "https://ilcorano.net/il-sacro-corano/92-sura-al-layl-la-notte/",
                  "https://ilcorano.net/il-sacro-corano/93-sura-ad-duha-la-luce-del-mattino/",
                  "https://ilcorano.net/il-sacro-corano/94-sura-ash-sharh-lapertura/",
                  "https://ilcorano.net/il-sacro-corano/95-sura-at-tin-il-fico/",
                  "https://ilcorano.net/il-sacro-corano/96-sura-al-alaq-laderenza/",
                  "https://ilcorano.net/il-sacro-corano/97-sura-al-qadr-il-destino/",
                  "https://ilcorano.net/il-sacro-corano/98-sura-al-bayyina-la-prova/",
                  "https://ilcorano.net/il-sacro-corano/99-sura-az-zalzalah-il-terremoto/",
                  "https://ilcorano.net/il-sacro-corano/100-sura-al-adiyat-le-scalpitanti/",
                  "https://ilcorano.net/il-sacro-corano/101-sura-al-qariah-la-percotente/",
                  "https://ilcorano.net/il-sacro-corano/102-sura-at-takathur-il-rivaleggiare/",
                  "https://ilcorano.net/il-sacro-corano/103-sura-al-asr-il-tempo/",
                  "https://ilcorano.net/il-sacro-corano/104-sura-al-humaza-il-diffamatore/",
                  "https://ilcorano.net/il-sacro-corano/105-sura-al-fil-lelefante/",
                  "https://ilcorano.net/il-sacro-corano/106-sura-quraysh-i-coreisciti/",
                  "https://ilcorano.net/il-sacro-corano/107-sura-al-maun-lutensile/",
                  "https://ilcorano.net/il-sacro-corano/108-sura-al-kawthar-labbondanza/",
                  "https://ilcorano.net/il-sacro-corano/109-sura-al-kafirun-i-miscredenti/",
                  "https://ilcorano.net/il-sacro-corano/110-sura-an-nasr-lausilio/",
                  "https://ilcorano.net/il-sacro-corano/111-sura-al-masad-le-fibre-di-palma/",
                  "https://ilcorano.net/il-sacro-corano/112-sura-al-ikhlas-il-puro-monoteismo/",
                  "https://ilcorano.net/il-sacro-corano/113-sura-al-falaq-lalba-nascente/",
                  "https://ilcorano.net/il-sacro-corano/114-sura-an-nas-gli-uomini/"]


    surah_urls.each_with_index do |surah_url, i|
      chapter = Chapter.find_by_chapter_number(i + 1)
      chapter_page = agent.get(surah_url)
      parse_chapter_info(chapter, chapter_page, language, info_resource_content)

      verse = nil
      translation = nil

      chapter_page.search(".entry-content").children.each_with_index do |child, child_index|
        next if 'p' != child.name
        break if ((chapter.chapter_number == 1 && child_index == 12) || ('hr' == child.name)) # first chapter doesn't have hr so manually break it after index 12 
        verse_number = child.text.match(VERSE_START_REG)[0].tr!('.', '').strip rescue nil # this force only numbers which ends with a dot 
        if verse_number
          # if paragragh starts with a number then we will assume its a start of an verse.
          puts "#{chapter.id}:#{verse_number}"
          verse = chapter.verses.find_by_verse_number(verse_number)
          next if verse.blank?
          
          translation = verse.translations.where(resource_content_id: resource_content.id).first_or_create
          translation.text = "#{translation.text} #{child.content}"
          translation.save(validate: false)
        else
          # this will help us to skip starting paragraphs because at that time translation will be nil
          if translation
            translation.text = "#{translation.text} #{child.content}"
            translation.save(validate: false)
          end
        end
      end

      # Now fix footnotes
      Translation.where(resource_content: resource_content, verse_id: chapter.verses.pluck(:id)).each do |translation|
        translation.foot_notes.delete_all
        parse_foot_note(translation, chapter_page, language, footnote_resource_content, resource_content)
      end
    end

    if Translation.where(resource_content_id: 153).count != Verse.count
      missing = []

      Verse.find_each do |v|
        if v.translations.where(resource_content_id: 153).blank?
          missing << v.verse_key
        end
      end

      puts "Missing ayah: #{missing}"
    end
  end

  def parse_foot_note(translation, page, language, footnote_resource_content, resource_content)
    text = translation.text
    foot_note_counter = 0
    partial_footnotes = false

    text_with_footnotes = text.gsub /\[\d+\]/ do |num|
      num = num[/\d+/]

      dom = (page.search("#_ftn#{num}")[0] || page.search("[name=_ftn#{num}]")[0])

      if dom
        while !(dom.name == 'p' || dom.name == 'div')
          dom = dom.parent
        end

        foot_note_doms = [dom]

        if partial_footnotes
          next_dom = dom.next
          while next_dom && !next_dom.to_s.match(/id="_ftn\d+/)
            foot_note_doms.push(next_dom)
            next_dom = next_dom.next
          end
        end

        foot_note_doms = foot_note_doms.map do |dom|
          "<p>#{dom.text.gsub(/\[\d+\]/, '').strip}</p>"
        end

        foot_note = translation.foot_notes.create(text: foot_note_doms.join(' '), language: language, language_name: language.name.downcase, resource_content: footnote_resource_content)

        "<a class=f><sup foot_note=#{foot_note.id}>#{foot_note_counter += 1}</sup></a>"
      else
        ''
      end
    end

    translation.text = text_with_footnotes.gsub(/\d+(.)?\s/, '').strip
    translation.language = language
    translation.language_name = language.name.downcase
    translation.resource_name = resource_content.name
    translation.priority = resource_content.priority
    translation.save
  end

  def parse_chapter_info(chapter, page, language, info_resource_content)
    title = page.search(".entry-title").text

    if (match = title.match(SURAH_NAME_REGEXP))
      surah_name = match[0].tr "()", ''
    else
      surah_name = title.gsub /\d+(\s*–\s)*Surat\s+/, ''
    end

    chapter.translated_names.where(language_id: language.id).first_or_create({
                                                                                 name: surah_name,
                                                                                 language_name: language.name.downcase
                                                                             })

    dom = page.search("#_ftn1")[0]
    if dom
      dom = dom.parent

      info_doms = []
      while dom.name != 'p'
        dom = dom.parent
      end

      info_doms.push(dom)

      next_dom = dom.next

      while next_dom && !next_dom.to_s.match(/id="_ftn\d+/)
        info_doms.push(next_dom)
        next_dom = next_dom.next
      end

      info_doms = info_doms.map do |dom|
        "<p>#{dom.text.gsub(/\[\d+\]/, '').strip}</p>"
      end

      info = chapter.chapter_infos.where(language: language).first_or_create(
          text: info_doms.join(' '),
          source: "(la traduzione dei suoi significati in lingua italiana) A cura di Hamza Roberto Piccardo"
      )

      info.resource_content = info_resource_content
      info.save
    end
  end

end