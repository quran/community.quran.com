namespace :quranenc_importer do
  def parse_indonesian_sabiq(rows, resource)
    footnote_resource_content = ResourceContent.where({
                                                          author_id: resource.author_id,
                                                          author_name: resource.author.name,
                                                          resource_type: "content",
                                                          sub_type: "footnote",
                                                          name: resource.name,
                                                          description: "#{resource.name} footnotes",
                                                          cardinality_type: "1_ayah",
                                                          language_id: resource.language.id,
                                                          language_name: resource.language.name.downcase,
                                                      }).first_or_create

    rows.each do |row|
      verse = Verse.find_by_verse_key("#{row[1]}:#{row[2]}")

      footnote = encode_and_clean_text(row[4])

      translation = create_translation(verse, row[3], resource)
      text = translation.text
      translation.foot_notes.delete_all

      footnote_ids = text.scan(/[\*]+\(\d+\)/)
      footnotes = footnote.split(/[\*]+\d+\)./).select(&:present?)

      footnote_ids.each_with_index do |node, i|
        footnote = translation.foot_notes.create(text: footnotes[i].to_s.strip, language: resource.language, language_name: resource.language.name.downcase, resource_content: footnote_resource_content)

        text = text.gsub("#{node}", "<sup foot_note=#{footnote.id}>#{i + 1}</sup>")
      end

      if footnote_ids.blank? && footnotes.present?
        footnote = translation.foot_notes.create(text: footnotes.map(&:strip).join("\n"), language: resource.language, language_name: resource.language.name.downcase, resource_content: footnote_resource_content)

        text = ("#{text}" "<sup foot_note=#{footnote.id}>1</sup>")
      end

      translation.text = text.sub(/\d+[.]/, '').strip

      translation.save

      puts translation.id
    end
  end

  def parse_portuguese_nasr(rows, resource)
    footnote_resource_content = ResourceContent.where({
                                                          author_id: resource.author_id,
                                                          author_name: resource.author.name,
                                                          resource_type: "content",
                                                          sub_type: "footnote",
                                                          name: resource.name,
                                                          description: "#{resource.name} footnotes",
                                                          cardinality_type: "1_ayah",
                                                          language_id: resource.language.id,
                                                          language_name: resource.language.name.downcase,
                                                      }).first_or_create

    resource.save
    rows.each do |row|
      verse = Verse.find_by_verse_key("#{row[1]}:#{row[2]}")

      footnote = encode_and_clean_text(row[4].to_s)

      translation = create_translation(verse, row[3], resource)
      text = translation.text
      translation.foot_notes.delete_all

      footnote_ids = text.scan(/\(\d+\)/)
      footnotes = footnote.split(/\(\d+\)./).select(&:present?)

      footnote_ids.each_with_index do |node, i|
        footnote = translation.foot_notes.create(text: footnotes[i].to_s.strip, language: resource.language, language_name: resource.language.name.downcase, resource_content: footnote_resource_content)

        text = text.gsub("#{node}", "<sup foot_note=#{footnote.id}>#{i + 1}</sup>")
      end

      if footnote_ids.blank? && footnotes.present?
        footnote = translation.foot_notes.create(text: footnotes.map(&:strip).join("\n"), language: resource.language, language_name: resource.language.name.downcase, resource_content: footnote_resource_content)

        text = ("#{text}" "<sup foot_note=#{footnote.id}>1</sup>")
      end

      translation.text = text.sub(/\d+[.]/, '').strip
      translation.save

      puts translation.id
    end
  end

  def parse_uzbek_mansour(rows, resource)
    footnote_resource_content = ResourceContent.where({
                                                          author_id: resource.author_id,
                                                          author_name: resource.author.name,
                                                          resource_type: "content",
                                                          sub_type: "footnote",
                                                          name: resource.name,
                                                          description: "#{resource.name} footnotes",
                                                          cardinality_type: "1_ayah",
                                                          language_id: resource.language.id,
                                                          language_name: resource.language.name.downcase,
                                                      }).first_or_create

    rows.each do |row|
      verse = Verse.find_by_verse_key("#{row[1]}:#{row[2]}")

      footnote = encode_and_clean_text(row[4].to_s)

      translation = create_translation(verse, row[3], resource)
      text = translation.text
      translation.foot_notes.delete_all
      translation.save

      if footnote.present?
        _footnote = translation.foot_notes.create(text: footnote.strip, language: resource.language, language_name: resource.language.name.downcase, resource_content: footnote_resource_content)

        text = ("#{text}" "<sup foot_note=#{_footnote.id}>1</sup>")
      end

      translation.text = text.sub(/\d+[.]/, '').strip
      translation.save

      puts translation.id
    end
  end

  def parse_uzbek_sadiq(rows, resource)
    footnote_resource_content = ResourceContent.where({
                                                          author_id: resource.author_id,
                                                          author_name: resource.author.name,
                                                          resource_type: "content",
                                                          sub_type: "footnote",
                                                          name: resource.name,
                                                          description: "#{resource.name} footnotes",
                                                          cardinality_type: "1_ayah",
                                                          language_id: resource.language.id,
                                                          language_name: resource.language.name.downcase,
                                                      }).first_or_create

    rows.each do |row|
      verse = Verse.find_by_verse_key("#{row[1]}:#{row[2]}")

      footnote = encode_and_clean_text(row[4].to_s)

      translation = create_translation(verse, row[3], resource)
      translation.foot_notes.delete_all

      if footnote.present?
        _footnote = translation.foot_notes.create(text: footnote.strip, language: resource.language, language_name: resource.language.name.downcase, resource_content: footnote_resource_content)

        text = ("#{text}" "<sup foot_note=#{_footnote.id}>1</sup>")
      end

      translation.text = text.sub(/\d+[.]/, '').strip
      translation.save

      puts translation.id
    end
  end

  def parse_yoruba_mikail(rows, resource)
    footnote_resource_content = ResourceContent.where({
                                                          author_id: resource.author_id,
                                                          author_name: resource.author.name,
                                                          resource_type: "content",
                                                          sub_type: "footnote",
                                                          name: resource.name,
                                                          description: "#{resource.name} footnotes",
                                                          cardinality_type: "1_ayah",
                                                          language_id: resource.language.id,
                                                          language_name: resource.language.name.downcase,
                                                      }).first_or_create

    rows.each do |row|
      verse = Verse.find_by_verse_key("#{row[1]}:#{row[2]}")

      footnote = encode_and_clean_text(row[4].to_s)

      translation = create_translation(verse, row[3], resource)
      text = translation.text
      translation.foot_notes.delete_all

      if footnote.present?
        _footnote = translation.foot_notes.create(text: footnote.strip, language: resource.language, language_name: resource.language.name.downcase, resource_content: footnote_resource_content)

        text = ("#{text}" "<sup foot_note=#{_footnote.id}>1</sup>")
      end

      translation.text = text.sub(/\d+[.]/, '').strip
      translation.save

      puts translation.id
    end
  end

  def parse_urdu_junagarhi(rows, resource)
    footnote_resource_content = ResourceContent.where({
                                                          author_id: resource.author_id,
                                                          author_name: resource.author.name,
                                                          resource_type: "content",
                                                          sub_type: "footnote",
                                                          name: resource.name,
                                                          description: "#{resource.name} footnotes",
                                                          cardinality_type: "1_ayah",
                                                          language_id: resource.language.id,
                                                          language_name: resource.language.name.downcase,
                                                      }).first_or_create

    rows.each do |row|
      verse = Verse.find_by_verse_key("#{row[1]}:#{row[2]}")

      footnote = encode_and_clean_text(row[4].to_s)

      translation = create_translation(verse, row[3], resource)
      text = translation.text

      translation.foot_notes.delete_all
      translation.save

      footnote_ids = text.scan(/[\*]+/)
      footnotes = footnote.split(/[\*]+/).select(&:present?)

      footnotes.present? && footnote_ids.each_with_index do |node, i|
        if footnotes[i]
          footnote = translation.foot_notes.create(text: footnotes[i].strip, language: resource.language, language_name: resource.language.name.downcase, resource_content: footnote_resource_content)

          text = text.sub("#{node}", "<sup foot_note=#{footnote.id}>#{i + 1}</sup>")
        end
      end

      if footnote_ids.blank? && footnotes.present?
        footnote = translation.foot_notes.create(text: footnotes.map(&:strip).join("\n"), language: resource.language, language_name: resource.language.name.downcase, resource_content: footnote_resource_content)

        text = ("#{text}" "<sup foot_note=#{footnote.id}>1</sup>")
      end

      translation.text = text.sub(/\d+[.]/, '').strip
      translation.save

      puts translation.id
    end
  end

  def parse_hindi_omari(rows, resource)
    footnote_resource_content = ResourceContent.where({
                                                          author_id: resource.author_id,
                                                          author_name: resource.author.name,
                                                          resource_type: "content",
                                                          sub_type: "footnote",
                                                          name: resource.name,
                                                          description: "#{resource.name} footnotes",
                                                          cardinality_type: "1_ayah",
                                                          language_id: resource.language.id,
                                                          language_name: resource.language.name.downcase,
                                                      }).first_or_create

    rows.each do |row|
      verse = Verse.find_by_verse_key("#{row[1]}:#{row[2]}")

      footnote = encode_and_clean_text(row[4].to_s)

      translation = create_translation(verse, row[3], resource)
      text = translation.text
      translation.foot_notes.delete_all

      footnote_ids = text.scan(/\[\d+\]/)
      footnotes = footnote.split(/\d+./).select(&:present?)

      footnote_ids.each_with_index do |node, i|
        footnote = translation.foot_notes.create(text: footnotes[i].to_s.strip, language: resource.language, language_name: resource.language.name.downcase, resource_content: footnote_resource_content)

        text = text.gsub("#{node}", "<sup foot_note=#{footnote.id}>#{i + 1}</sup>")
      end

      if footnote_ids.blank? && footnotes.present?
        footnote = translation.foot_notes.create(text: footnotes.map(&:strip).join("\n"), language: resource.language, language_name: resource.language.name.downcase, resource_content: footnote_resource_content)

        text = ("#{text}" "<sup foot_note=#{footnote.id}>1</sup>")
      end

      translation.text = text.sub(/\d+[.]/, '').strip
      translation.save

      puts translation.id
    end
  end

  def parse_hausa_gummi(rows, resource)
    footnote_resource_content = ResourceContent.where({
                                                          author_id: resource.author_id,
                                                          author_name: resource.author.name,
                                                          resource_type: "content",
                                                          sub_type: "footnote",
                                                          name: resource.name,
                                                          description: "#{resource.name} footnotes",
                                                          cardinality_type: "1_ayah",
                                                          language_id: resource.language.id,
                                                          language_name: resource.language.name.downcase,
                                                      }).first_or_create

    rows.each do |row|
      verse = Verse.find_by_verse_key("#{row[1]}:#{row[2]}")

      footnote = encode_and_clean_text(row[4].to_s)

      translation = create_translation(verse, row[3], resource)
      text = translation.text

      footnote_ids = text.scan(/[\*]+/)
      footnotes = footnote.split(/[\*]+/).select(&:present?)

      footnotes.present? && footnote_ids.each_with_index do |node, i|
        footnote = translation.foot_notes.create(text: footnotes[i].strip, language: resource.language, language_name: resource.language.name.downcase, resource_content: footnote_resource_content)

        text = text.gsub("#{node}", "<sup foot_note=#{footnote.id}>#{i + 1}</sup>")
      end


      if footnote_ids.blank? && footnotes.present?
        footnote = translation.foot_notes.create(text: footnotes.map(&:strip).join("\n"), language: resource.language, language_name: resource.language.name.downcase, resource_content: footnote_resource_content)

        text = ("#{text}" "<sup foot_note=#{footnote.id}>1</sup>")
      end

      translation.text = text.sub(/\d+[.]/, '').strip
      translation.save

      puts translation.id
    end
  end

  def parse_english_saheeh(rows, resource)
    footnote_resource_content = ResourceContent.where({
                                                          author_id: resource.author_id,
                                                          author_name: resource.author.name,
                                                          resource_type: "content",
                                                          sub_type: "footnote",
                                                          name: resource.name,
                                                          description: "#{resource.name} footnotes",
                                                          cardinality_type: "1_ayah",
                                                          language_id: resource.language.id,
                                                          language_name: resource.language.name.downcase,
                                                      }).first_or_create

    rows.each do |row|
      verse = Verse.find_by_verse_key("#{row[1]}:#{row[2]}")

      footnote = encode_and_clean_text(row[4].to_s)

      translation = create_translation(verse, row[3], resource)
      text = translation.text
      translation.foot_notes.delete_all


      footnote_ids = text.scan(/\[\d+\]/)
      footnotes = footnote.split(/\[\d+\]-/).select(&:present?)

      footnote_ids.each_with_index do |node, i|
        footnote = translation.foot_notes.create(text: footnotes[i].to_s.strip, language: resource.language, language_name: resource.language.name.downcase, resource_content: footnote_resource_content)

        text = text.gsub("#{node}", "<sup foot_note=#{footnote.id}>#{i + 1}</sup>")
      end

      if footnote_ids.blank? && footnotes.present?
        footnote = translation.foot_notes.create(text: footnotes.map(&:strip).join("\n"), language: resource.language, language_name: resource.language.name.downcase, resource_content: footnote_resource_content)

        text = ("#{text}" "<sup foot_note=#{footnote.id}>1</sup>")
      end

      translation.text = text.sub(/\d+[.]/, '').strip
      translation.save

      puts translation.id
    end
  end

  def parse_english_hilali_khan(rows, resource)
    footnote_resource_content = ResourceContent.where({
                                                          author_id: resource.author_id,
                                                          author_name: resource.author.name,
                                                          resource_type: "content",
                                                          sub_type: "footnote",
                                                          name: resource.name,
                                                          description: "#{resource.name} footnotes",
                                                          cardinality_type: "1_ayah",
                                                          language_id: resource.language.id,
                                                          language_name: resource.language.name.downcase,
                                                      }).first_or_create

    rows.each do |row|
      verse = Verse.find_by_verse_key("#{row[1]}:#{row[2]}")

      footnote = encode_and_clean_text(row[4].to_s)

      translation = create_translation(verse, row[3], resource)
      text = translation.text
      translation.foot_notes.delete_all

      footnote_ids = text.scan(/\[\d+\]/)
      footnotes = footnote.split(/\[\d+\]/).select(&:present?)

      footnote_ids.each_with_index do |node, i|
        footnote = translation.foot_notes.create(text: footnotes[i].to_s.strip, language: resource.language, language_name: resource.language.name.downcase, resource_content: footnote_resource_content)

        text = text.gsub("#{node}", "<sup foot_note=#{footnote.id}>#{i + 1}</sup>")
      end

      if footnote_ids.blank? && footnotes.present?
        footnote = translation.foot_notes.create(text: footnotes.map(&:strip).join("\n"), language: resource.language, language_name: resource.language.name.downcase, resource_content: footnote_resource_content)

        text = ("#{text}" "<sup foot_note=#{footnote.id}>1</sup>")
      end

      translation.text = text.sub(/\d+[.]/, '').strip
      translation.save

      puts translation.id
    end
  end

  def parse_french_montada(rows, resource)
    footnote_resource_content = ResourceContent.where({
                                                          author_id: resource.author_id,
                                                          author_name: resource.author.name,
                                                          resource_type: "content",
                                                          sub_type: "footnote",
                                                          name: resource.name,
                                                          description: "#{resource.name} footnotes",
                                                          cardinality_type: "1_ayah",
                                                          language_id: resource.language.id,
                                                          language_name: resource.language.name.downcase,
                                                      }).first_or_create

    rows.each do |row|
      verse = Verse.find_by_verse_key("#{row[1]}:#{row[2]}")

      footnote = encode_and_clean_text(row[4].to_s)

      translation = create_translation(verse, row[3], resource)
      text = translation.text
      translation.foot_notes.delete_all

      footnote_ids = text.scan(/\[\d+\]/)
      footnotes = footnote.split(/\[\d+\]/).select(&:present?)

      footnote_ids.each_with_index do |node, i|
        footnote = translation.foot_notes.create(text: footnotes[i].to_s.strip, language: resource.language, language_name: resource.language.name.downcase, resource_content: footnote_resource_content)

        text = text.gsub("#{node}", "<sup foot_note=#{footnote.id}>#{i + 1}</sup>")
      end

      if footnote_ids.blank? && footnotes.present?
        footnote = translation.foot_notes.create(text: footnotes.map(&:strip).join("\n"), language: resource.language, language_name: resource.language.name.downcase, resource_content: footnote_resource_content)

        text = ("#{text}" "<sup foot_note=#{footnote.id}>1</sup>")
      end

      translation.text = text.gsub(/\d+[.]/, '').strip

      translation.save

      puts translation.id
    end
  end

  def parse_albanian_nahi(rows, resource)
    footnote_resource_content = ResourceContent.where({
                                                          author_id: resource.author_id,
                                                          author_name: resource.author.name,
                                                          resource_type: "content",
                                                          sub_type: "footnote",
                                                          name: resource.name,
                                                          description: "#{resource.name} footnotes",
                                                          cardinality_type: "1_ayah",
                                                          language_id: resource.language.id,
                                                          language_name: resource.language.name.downcase,
                                                      }).first_or_create

    rows.each do |row|
      verse = Verse.find_by_verse_key("#{row[1]}:#{row[2]}")

      footnote = encode_and_clean_text(row[4].to_s)
      translation = create_translation(verse, row[3], resource)
      text = translation.text

      if footnote.present?
        translation.foot_notes.delete_all

        footnote_ids = text.scan(/\[\d+\]/)
        footnotes = footnote.split(/\[\d+\]/).select(&:present?)

        footnote_ids.each_with_index do |node, i|
          footnote = translation.foot_notes.create(text: footnotes[i].to_s.strip, language: resource.language, language_name: resource.language.name.downcase, resource_content: footnote_resource_content)

          text = text.gsub("#{node}", "<sup foot_note=#{footnote.id}>#{i + 1}</sup>")
        end

        translation.text = text.sub(/\d+[.]/, '').strip
        translation.save

        puts translation.id
      end
    end
  end

  def parse_indonesian_affairs(rows, resource)
    footnote_resource_content = ResourceContent.where({
                                                          author_id: resource.author_id,
                                                          author_name: resource.author.name,
                                                          resource_type: "content",
                                                          sub_type: "footnote",
                                                          name: resource.name,
                                                          description: "#{resource.name} footnotes",
                                                          cardinality_type: "1_ayah",
                                                          language_id: resource.language.id,
                                                          language_name: resource.language.name.downcase,
                                                      }).first_or_create

    rows.each do |row|
      verse = Verse.find_by_verse_key("#{row[1]}:#{row[2]}")

      footnote = encode_and_clean_text(row[4].to_s)
      translation = create_translation(verse, row[3], resource)
      text = translation.text

      footnote_ids = text.scan(/\d+\)/)
      footnotes = footnote.split(/\*\d+\)/).select(&:present?)

      footnote_ids.each_with_index do |node, i|
        footnote = translation.foot_notes.create(text: footnotes[i].to_s.strip, language: resource.language, language_name: resource.language.name.downcase, resource_content: footnote_resource_content)

        text = text.gsub("#{node}", "<sup foot_note=#{footnote.id}>#{i + 1}</sup>")
      end

      if footnote_ids.blank? && footnotes.present?
        footnote = translation.foot_notes.create(text: footnotes.map(&:strip).join("\n"), language: resource.language, language_name: resource.language.name.downcase, resource_content: footnote_resource_content)

        text = ("#{text}" "<sup foot_note=#{footnote.id}>1</sup>")
      end

      translation.text = text.sub(/\d+[.]/, '').strip
      translation.save

      puts translation.id
    end
  end

  def parse_indonesian_complex(rows, resource)
    footnote_resource_content = ResourceContent.where({
                                                          author_id: resource.author_id,
                                                          author_name: resource.author.name,
                                                          resource_type: "content",
                                                          sub_type: "footnote",
                                                          name: resource.name,
                                                          description: "#{resource.name} footnotes",
                                                          cardinality_type: "1_ayah",
                                                          language_id: resource.language.id,
                                                          language_name: resource.language.name.downcase,
                                                      }).first_or_create

    rows.each do |row|
      verse = Verse.find_by_verse_key("#{row[1]}:#{row[2]}")

      footnote = encode_and_clean_text(row[4].to_s)
      translation = create_translation(verse, row[3], resource)
      text = translation.text

      footnote_ids = text.scan(/\d+/)
      footnotes = footnote.split(/\d+[\.\s]/).select(&:present?)

      footnote_ids.each_with_index do |node, i|
        footnote = translation.foot_notes.create(text: footnotes[i].to_s.strip, language: resource.language, language_name: resource.language.name.downcase, resource_content: footnote_resource_content)

        text = text.gsub("#{node}", "<sup foot_note=#{footnote.id}>#{i + 1}</sup>")
      end

      if footnote_ids.blank? && footnotes.present?
        footnote = translation.foot_notes.create(text: footnotes.map(&:strip).join("\n"), language: resource.language, language_name: resource.language.name.downcase, resource_content: footnote_resource_content)

        text = ("#{text}" "<sup foot_note=#{footnote.id}>1</sup>")
      end

      translation.text = text.sub(/\d+[.]/, '').strip
      translation.save

      puts translation.id
    end
  end

  def create_translation(verse, text, resource)
    translation = verse.translations.where(resource_content: resource).first_or_create
    translation.language = resource.language
    translation.language_name = resource.language.name.downcase
    translation.resource_name = resource.name

    translation.text = encode_and_clean_text(text)
    translation.save
    puts translation.id

    translation
  end

  def parse_pashto_zakaria(rows, resource)
    rows.each do |row|
      verse = Verse.find_by_verse_key("#{row[1]}:#{row[2]}")

      text = row[3].sub(/\d+-\d+/,'')
      create_translation(verse, text, resource)
    end
  end

  def parse_spanish_garcia(rows, resource)
    footnote_resource_content = ResourceContent.where({
                                                          author_id: resource.author_id,
                                                          author_name: resource.author.name,
                                                          resource_type: "content",
                                                          sub_type: "footnote",
                                                          name: resource.name,
                                                          description: "#{resource.name} footnotes",
                                                          cardinality_type: "1_ayah",
                                                          language_id: resource.language.id,
                                                          language_name: resource.language.name.downcase,
                                                      }).first_or_create

    rows.each do |row|
      verse = Verse.find_by_verse_key("#{row[1]}:#{row[2]}")

      footnote = encode_and_clean_text(row[4].to_s)
      translation = create_translation(verse, row[3], resource)
      text = translation.text

      if footnote.present?
        _footnote = translation.foot_notes.create(text: footnote.strip, language: resource.language, language_name: resource.language.name.downcase, resource_content: footnote_resource_content)

        text = ("#{text}" "<sup foot_note=#{footnote.id}>1</sup>")
      end

      translation.text = text.sub(/\d+[.]/, '').strip
      translation.save

      puts translation.id
    end
  end

  def parse_spanish_montada_eu(rows, resource)
    footnote_resource_content = ResourceContent.where({
                                                          author_id: resource.author_id,
                                                          author_name: resource.author.name,
                                                          resource_type: "content",
                                                          sub_type: "footnote",
                                                          name: resource.name,
                                                          description: "#{resource.name} footnotes",
                                                          cardinality_type: "1_ayah",
                                                          language_id: resource.language.id,
                                                          language_name: resource.language.name.downcase,
                                                      }).first_or_create

    rows.each do |row|
      verse = Verse.find_by_verse_key("#{row[1]}:#{row[2]}")

      footnote = encode_and_clean_text(row[4].to_s)
      translation = create_translation(verse, row[3], resource)
      text = translation.text

      if footnote.present?
        translation.foot_notes.delete_all

        footnote_ids = text.scan(/\[\d+\]/)
        footnotes = footnote.split(/\[\d+\]/).select(&:present?)

        footnote_ids.each_with_index do |node, i|
          footnote = translation.foot_notes.create(text: footnotes[i].to_s.strip, language: resource.language, language_name: resource.language.name.downcase, resource_content: footnote_resource_content)

          text = text.gsub("#{node}", "<sup foot_note=#{footnote.id}>#{i + 1}</sup>")
        end

        translation.text = text.sub(/\d+[.]/, '').strip
        translation.save

        puts translation.id
      end
    end
  end

  def parse_tajik_khawaja(rows, resource)
    footnote_resource_content = ResourceContent.where({
                                                          author_id: resource.author_id,
                                                          author_name: resource.author.name,
                                                          resource_type: "content",
                                                          sub_type: "footnote",
                                                          name: resource.name,
                                                          description: "#{resource.name} footnotes",
                                                          cardinality_type: "1_ayah",
                                                          language_id: resource.language.id,
                                                          language_name: resource.language.name.downcase,
                                                      }).first_or_create

    resource.save
    rows.each do |row|
      verse = Verse.find_by_verse_key("#{row[1]}:#{row[2]}")

      footnote = encode_and_clean_text(row[4].to_s)

      translation = create_translation(verse, row[3], resource)
      text = translation.text
      translation.foot_notes.delete_all

      footnote_ids = text.scan(/\(\d+\)/)
      footnotes = footnote.split(/\d+[.]/).select(&:present?)

      footnote_ids.each_with_index do |node, i|
        footnote = translation.foot_notes.create(text: footnotes[i].to_s.strip, language: resource.language, language_name: resource.language.name.downcase, resource_content: footnote_resource_content)

        text = text.gsub("#{node}", "<sup foot_note=#{footnote.id}>#{i + 1}</sup>")
      end

      if footnote_ids.blank? && footnotes.present?
        footnote = translation.foot_notes.create(text: footnotes.map(&:strip).join("\n"), language: resource.language, language_name: resource.language.name.downcase, resource_content: footnote_resource_content)

        text = ("#{text}" "<sup foot_note=#{footnote.id}>1</sup>")
      end

      translation.text = text.sub(/\d+[.]/, '').strip
      translation.save

      puts translation.id
    end
  end

  def parse_uyghur_saleh(rows, resource)
    rows.each do |row|
      verse = Verse.find_by_verse_key("#{row[1]}:#{row[2]}")

      text = row[3].sub /\[\d+\]/, ''
      create_translation(verse, text, resource)
    end
  end

  def encode_and_clean_text(text)
    text = text.to_s

    if text.valid_encoding?
      text
    else
      text.scrub
    end.to_s
        .sub('#', '')
        .sub('#VALUE!', '')
        .strip
  end

  task import_all: :environment do
    PaperTrail.enabled = false

    require 'csv'
    data_source = DataSource.find_or_create_by(name: 'Quranenc', url: 'https://quranenc.com')

    resource_content_mapping = {
        albanian_nahi: {language: 187, author_name: 'Hasan Efendi Nahi', id: 88}, #88,
        amharic_sadiq: {language: 6, author_name: 'Sadiq and Sani', id: 87}, #87,
        assamese_rafeeq: {language: 10, author_name: 'Shaykh Rafeequl Islam Habibur-Rahman', id: 120},
        bosnian_korkut: {language: 23, author_name: 'Besim Korkut', id: 126}, #126,
        bosnian_mihanovich: {language: 23, author_name: 'Muhamed Mehanović', id: 25},
        chinese_makin: {language: 185, author_name: 'Muhammad Makin', id: 109},
        english_hilali_khan: {language: 38, author_name: 'Muhammad Taqi-ud-Din al-Hilali & Muhammad Muhsin Khan', id: 105},
        english_saheeh: {language: 38, author_name: 'Saheeh International', id: 20}, #20,
        french_montada: {language: 49, author_name: 'Montada Islamic Foundation'},
        german_bubenheim: {language: 33, author_name: 'Frank Bubenheim and Nadeem', id: 27},
        hausa_gummi: {language: 58, author_name: 'Abubakar Mahmood Jummi', id: 115},
        hindi_omari: {language: 60, author_name: 'Maulana Azizul Haque al-Umari', id: 122},
        indonesian_affairs: {language: 67, author_name: 'Indonesian Islamic affairs ministry', id: 33},
        indonesian_complex: {language: 67, author_name: 'King Fahad Quran Complex'},
        indonesian_sabiq: {language: 33, author_name: 'The Sabiq company'},
        japanese_meta: {language: 76, author_name: 'Ryoichi Mita', id: 35}, #35,
        kazakh_altai_assoc: {language: 82, author_name: 'Khalifah Altai', id: 113},
        khmer_cambodia: {language: 84, author_name: 'Cambodian Muslim Community Development', id: 128},
        kurdish_bamoki: {language: 89, author_name: 'Muhammad Saleh Bamoki'},
        oromo_ababor: {language: 126, author_name: 'Ghali Apapur Apaghuna', id: 111},
        pashto_zakaria: {language: 132, author_name: 'Zakaria Abulsalam', id: 118},
        persian_ih: {language: 43, author_name: 'IslamHouse.com'},
        persian_tagi: {language: 43, author_name: 'Dr. Hussien Tagi'},
        portuguese_nasr: {language: 133, author_name: 'Helmi Nasr', id: 103},
        spanish_garcia: {language: 40, author_name: 'Muhammad Isa Garcia'},
        spanish_montada_eu: {language: 40, author_name: 'Montada Islamic Foundation'},
        tajik_khawaja: {language: 160, author_name: 'Khawaja Mirof & Khawaja Mir'},
        tamil_baqavi: {language: 158, author_name: 'Abdul Hameed Baqavi'},
        turkish_shaban: {language: 167, author_name: 'Shaban Britch', id: 112},
        turkish_shahin: {language: 167, author_name: 'Muslim Shahin', id: 124},
        urdu_junagarhi: {language: 174, author_name: 'مولانا محمد جوناگڑھی', id: 54}, #54,
        uyghur_saleh: {language: 172, author_name: 'Shaykh Muhammad Saleh'},
        uzbek_mansour: {language: 175, author_name: 'Alauddin Mansour', id: 101},
        uzbek_sadiq: {language: 175, author_name: 'Muhammad Sodik Muhammad Yusuf', id: 55}, #55,
        yoruba_mikail: {language: 183, author_name: 'Shaykh Abu Rahimah Mikael Aykyuni', id: 125},

        french_hameedullah: {language: 49, author_name: 'Muhammad Hamidullah', id: 31}, #31,
        nepali_central: {language: 116, author_name: 'Ahl Al-Hadith Central Society of Nepal'},
    }

    translation_with_footnotes = [
        'albanian_nahi', 'english_hilali_khan', 'english_saheeh',
        'hausa_gummi', 'hindi_omari', 'indonesian_sabiq', 'portuguese_nasr',
        'urdu_junagarhi', 'uzbek_mansour', 'uzbek_sadiq', 'yoruba_mikail',
        'french_montada', 'indonesian_affairs', 'indonesian_complex',
        'spanish_garcia', 'spanish_montada_eu', 'tajik_khawaja'
    ]

    tafsirs = ['arabic_mokhtasar']

    Dir['data/csv/*'].each do |file|
      translation_name = file.split('/').last.split('.').first

      mapping = resource_content_mapping[translation_name.to_sym]
      language = Language.find(mapping[:language])
      author = Author.find_or_create_by(name: mapping[:author_name])

      resource = if mapping[:id]
                   ResourceContent.find(mapping[:id])
                 else
                   ResourceContent.find_or_create_by(
                       language: language,
                       data_source: data_source,
                       author_name: author.name,
                       author: author,
                       language_name: language.name.downcase,
                       cardinality_type: ResourceContent::CardinalityType::OneVerse,
                       sub_type: ResourceContent::SubType::Translation,
                       resource_type: ResourceContent::ResourceType::Content,
                   )
                 end

      resource.update_attributes(name: author.name, data_source: data_source, author_name: author.name)

      rows = CSV.open(file).read

      if translation_with_footnotes.include?(translation_name) || respond_to?("parse_#{translation_name}")
        send "parse_#{translation_name}", rows[2..rows.length], resource
      else
        rows[2..rows.length].each do |row|
          verse = Verse.find_by_verse_key("#{row[1]}:#{row[2]}")

          create_translation(verse, row[3].to_s, resource)
        end
      end
    end
  end
end