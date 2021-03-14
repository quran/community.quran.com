namespace :import_chechen do
  def process_foot_note_text_for_chechen(foot_note_node)
    foot_note_node = foot_note_node.ancestors('div').first

    # remove the links
    foot_note_node.search("a").remove

    white_list_sanitizer = Rails::Html::WhiteListSanitizer.new
    white_list_sanitizer.sanitize(foot_note_node.to_s.strip, tags: %w(sup p ol ul li b), attributes: []).gsub(/[\r\n]+/, "").gsub('&nbsp;', '').gsub(/\u00A0/, '')
  end

def run
    PaperTrail.enabled = false
    mapping = {
        1 => 'td.c11',
        2 => 'td.c12',
        3 => 'td.c9',
        4 => 'td.c11',
        5 => 'td.c18',
        6 => 'td.c6',
        7 => 'page 290', # in pdf 7 is replaced with 11
        8 => 'td.c4',

        #9 => 'li.c9.c20',
        9 => 'td.c8',

        10 => 'td.c4',
        11 => 'li.c5',
        12 => 'td.c5',
        13 => 'li.c5.c12',
        14 => 'li.c9',
        15 => 'td.c6',
        16 => 'td.c14',
        17 => 'td.c11',
        18 => 'td.c7',
        19 => 'li.c4.c11',
        20 => 'td.c12',
        21 => 'td.c10',
        22 => 'li.c7.c13',
        23 => 'td.c1',
        24 => 'td.c3',
        25 => 'li.c2',
        26 => 'td.c4',
        27 => 'li.c1',
        28 => 'li.c6',
        29 => 'li.c1.c6',
        30 => 'li.c5',
        31 => 'li.c4',
        32 => 'li.c7',
        33 => 'li.c11',
        34 => 'td.c11',
        35 => 'td.c2',
        36 => '.c6 .c5',
        37 => 'td.c3',
        38 => 'li.c7',
        39 => 'td.c9',
        40 => 'li.c10',
        41 => 'li.c8',
        42 => 'td.c10',
        43 => 'td.c1',
        44 => 'li.c11.c14',
        45 => 'li.c7',
        46 => 'li.c7',
        47 => 'td.c17',
        48 => 'li.c11.c13',
        49 => 'li.c5',
        50 => 'td.c12',
        51 => 'li.c2',
        52 => 'li.c7.c10',
        53 => 'li.c5',
        54 => 'li.c3',
        55 => 'td.c3',
        56 => 'td.c0',
        57 => 'td.c7',
        58 => 'li.c10.c15',
        59 => 'li.c5.c6',
        60 => 'li.c1.c15',
        61 => 'li.c5',
        62 => 'td.c13',
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
        78 => 'td.c7',
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
        90 => 'td.c10',
        91 => 'li.c10',
        92 => 'li.c10',
        93 => 'li.c16.c18',
        94 => 'li.c7',
        95 => 'li.c3',
        96 => 'li.c8',
        97 => 'li.c4',
        98 => 'li.c0',
        99 => 'td.c8',
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

    author = Author.where(name: 'Magomed Magomedov').first_or_create
    language = Language.find_by_name 'Chechen'
    data_source = DataSource.where(name: "Movsar Bekaev - bekaev.movsar@gmail.com").first_or_create

    resource_content  = ResourceContent.find(106)

=begin
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
=end


    resource_content.priority = 4
    resource_content.save
    footnote_resource_content = ResourceContent.find(107)

=begin
    ResourceContent.where({
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
=end

    Translation.where(resource_content: resource_content).delete_all
    FootNote.where(resource_content: footnote_resource_content).delete_all

  files = Dir['chechen/*']

    files = files.sort do |f, f2|
      f[/\d+/].to_i <=> f2[/\d+/].to_i
    end

    files.each do |f|
      offset = 0
      content = File.open(f).read
      docs = Nokogiri.parse(content)
      chapter = Chapter.find(f[/\d+/])

      next if chapter.id == 7
      puts chapter.id

      verses = Verse.unscoped.where(chapter_id: chapter.id).order("verse_index ASC")

      if chapter.id != 1 && docs.search(mapping[chapter.id]).length != verses.count
        next
      end

      if 1 == chapter.id
        offset = 1

        verse = verses[0]
        verse_node = docs.search('#bismillah')

        translation = verse.translations.where(resource_content: resource_content, language: language).first_or_initialize
        translation.save validate: false

        text = verse_node.text

        verse_node.search("a").each_with_index do |footnote_node, f_i|
          footnote_id = footnote_node.attributes['href'].value
          number = footnote_id.scan(/\d/).join('')

          footnote_text = process_foot_note_text_for_chechen(docs.search(footnote_id).first)
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

      docs.search(mapping[chapter.id]).each_with_index do |verse_node, v_index|
        text = verse_node.text.strip.gsub(/\d+\./, ' ').gsub(/\u00A0/, '')
        verse = verses[v_index + offset]
        translation = verse.translations.where(resource_content: resource_content, language: language).first_or_initialize
        translation.save validate: false

        # puts "TRANSLATIONS  #{translation.id}"

        verse_node.search("a").each_with_index do |footnote_node, f_i|
          footnote_id = footnote_node.attributes['href'].value
          number = footnote_id.scan(/\d/).join('')

          footnote_text = process_foot_note_text_for_chechen(docs.search(footnote_id).first)
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
end