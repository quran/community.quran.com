namespace :quranenc_api do
  def fix_encoding(text)
    if text.valid_encoding?
      text
    else
      text.scrub
    end.to_s
        .strip
  end

  def with_rescue_retry(exceptions, on_exception: nil, retries: 5, raise_exception_on_limit: true)
    try = 0

    begin
      yield try
    rescue *exceptions => exc
      on_exception.call(exc) if on_exception
      sleep 2
      try += 1
      try <= retries ? retry : raise_exception_on_limit && raise
    end
  end

  def create_translation(verse, text, resource)
    translation = verse.translations.where(resource_content_id: resource.id).first_or_initialize
    translation.text = text

    begin
      translation.save
    rescue Exception => e
      Translation.connection.reset_pk_sequence!('translations')
      translation.save
    end

    translation
  end

  def create_translation_with_footnote(verse, verse_data, resource, footnote_resource_content, footnote_id_reg, footnote_text_reg)
    translation = create_translation(verse, fix_encoding(verse_data['translation']), resource)
    translation.save(validate: false)
    translation_text = translation.text

    if verse_data['footnotes'].present?
      translation.foot_notes.delete_all

      footnote_text = fix_encoding(verse_data['footnotes'].to_s)
      footnote_ids = if footnote_id_reg
                       translation_text.scan(footnote_id_reg)
                     else
                       []
                     end
      footnotes = if footnote_text_reg
                    footnote_text.split(footnote_text_reg).select(&:present?)
                  else
                    footnote_text.strip
                  end

      footnote_ids.each_with_index do |node, i|
        footnote = translation.foot_notes.create(text: footnotes[i].to_s.strip, language: resource.language, language_name: resource.language.name.downcase, resource_content: footnote_resource_content)

        translation_text = translation_text.gsub("#{node}", "<sup foot_note=#{footnote.id}>#{i + 1}</sup>")
      end

      if footnote_ids.blank? && footnotes.present?
        footnote = translation.foot_notes.create(text: footnotes, language: resource.language, language_name: resource.language.name.downcase, resource_content: footnote_resource_content)

        translation_text = "#{translation_text} <sup foot_note=#{footnote.id}>1</sup>"
      end

      translation.text = translation_text.sub(/\d+[.]/, '').strip
    end

    translation
  end

  def parse_pashto_zakaria(verse, verse_data, resource)
    text = verse_data['translation'].sub(/\d+-\d+/, '')
    create_translation(verse, text, resource)
  end

  def parse_uyghur_saleh(verse, verse_data, resource)
    text = verse_data['translation'].sub(/\[\d+\]/, '')
    create_translation(verse, text, resource)
  end

  task import_tafsir: :environment do
    PaperTrail.enabled = false

    tafsirs = {
        english_mokhtasar: {language: 38, name: 'English Mokhtasar'},
        turkish_mokhtasar: {language: 167, name: 'Turkish Mokhtasar'},
        french_mokhtasar: {language: 49, name: 'French Mokhtasar'},
        indonesian_mokhtasar: {language: 67, name: 'Indonesian Mokhtasar'},
        bosnian_mokhtasar: {language: 23, name: 'Bosnian Mokhtasar'},
        italian_mokhtasar: {language: 74, name: 'Italian Mokhtasar'},
        vietnamese_mokhtasar: {language: 177, name: 'Vietnamese Mokhtasar'},
        russian_mokhtasar: {language: 138, name: 'Russian Mokhtasar'},
        tagalog_mokhtasar: {language: 164, name: 'Tagalog Mokhtasar'},
        bengali_mokhtasar: {language: 20, name: 'Bengali Mokhtasar'},
        persian_mokhtasar: {language: 143, name: 'Persian Mokhtasar'},
        chinese_mokhtasar: {language: 185, name: 'Chinese Mokhtasar'},
        japanese_mokhtasar: {language: 76, name: 'Japanese Mokhtasar'}
    }

    data_source = DataSource.find_or_create_by(name: 'Quranenc', url: 'https://quranenc.com')
    author = Author.where(name: 'Al-Mukhtasar').first_or_create

    tafsirs.keys.each do |k|
      resource = if (id = tafsirs[k][:id])
                   ResourceContent.find(id)
                 else
                   language = Language.find(tafsirs[k][:language])

                   r = ResourceContent.where(
                       language: language,
                       data_source: data_source,
                       author_name: author.name,
                       author: author,
                       language_name: language.name.downcase,
                       cardinality_type: ResourceContent::CardinalityType::OneVerse,
                       sub_type: ResourceContent::SubType::Tafsir,
                       resource_type: ResourceContent::ResourceType::Content,
                   ).first_or_create

                   r.name = tafsirs[k][:name]
                   r.save
                   r
                 end

      puts "Importing tafisr #{k}"

      Chapter.find_each do |c|
        url = "https://quranenc.com/ar/api/translation/sura/#{k}/#{c.id}"

        response = with_rescue_retry([RestClient::Exceptions::ReadTimeout], retries: 3, raise_exception_on_limit: true) do
          RestClient.get(url)
        end

        data = JSON.parse(response.body)['result']

        data.each do |ayah_data|
          verse = Verse.find_by(verse_key: "#{ayah_data['sura']}:#{ayah_data['aya']}")

          text = fix_encoding(ayah_data['translation'])

          tafsir = Tafsir.where(verse_id: verse.id, language_id: language.id, resource_content_id: resource.id).first_or_initialize
          tafsir.resource_name = resource.name
          tafsir.text = text
          tafsir.language_name = language.name.downcase
          tafsir.resource_name = resource.name
          tafsir.verse_key = verse.verse_key
          tafsir.save
        end
      end
    end
  end

  task import: :environment do
    PaperTrail.enabled = false
    ActiveRecord::Base.logger = nil

    # agent = Mechanize.new
    # document = agent.get('https://quranenc.com/en/home#transes')
    # translations = document.search("a[@href^='https://quranenc.com/en/browse/']").map do |link|
    #  link.attr('href').split('/').last
    # end.select {|t| !t.include?('arabic')}

    resource_content_mapping = {
        albanian_nahi: {language: 187, author_name: 'Hasan Efendi Nahi', id: 88},
        amharic_sadiq: {language: 6, author_name: 'Sadiq and Sani', id: 87},
        assamese_rafeeq: {language: 10, author_name: 'Shaykh Rafeequl Islam Habibur-Rahman', id: 120},
        bosnian_korkut: {language: 23, author_name: 'Besim Korkut', id: 126},
        bosnian_mihanovich: {language: 23, author_name: 'Muhamed Mehanović', id: 25},
        chinese_makin: {language: 185, author_name: 'Muhammad Makin', id: 109},
        english_saheeh: {language: 38, author_name: 'Saheeh International', id: 20},
        french_montada: {language: 49, author_name: 'Montada Islamic Foundation'},
        german_bubenheim: {language: 33, author_name: 'Frank Bubenheim and Nadeem', id: 27},
        hausa_gummi: {language: 58, author_name: 'Abubakar Mahmood Jummi', id: 115},
        hindi_omari: {language: 60, author_name: 'Maulana Azizul Haque al-Umari', id: 122},
        indonesian_affairs: {language: 67, author_name: 'Indonesian Islamic affairs ministry', id: 33},
        indonesian_complex: {language: 67, author_name: 'King Fahad Quran Complex', id: 134},
        japanese_meta: {language: 76, author_name: 'Ryoichi Mita', id: 35},
        kazakh_altai_assoc: {language: 82, author_name: 'Khalifah Altai', id: 113},
        khmer_cambodia: {language: 84, author_name: 'Cambodian Muslim Community Development', id: 128},
        oromo_ababor: {language: 126, author_name: 'Ghali Apapur Apaghuna', id: 111},
        pashto_zakaria: {language: 132, author_name: 'Zakaria Abulsalam', id: 118},
        portuguese_nasr: {language: 133, author_name: 'Helmi Nasr', id: 103},
        turkish_shaban: {language: 167, author_name: 'Shaban Britch', id: 112},
        turkish_shahin: {language: 167, author_name: 'Muslim Shahin', id: 124},
        urdu_junagarhi: {language: 174, author_name: 'مولانا محمد جوناگڑھی', id: 54},
        uzbek_mansour: {language: 175, author_name: 'Alauddin Mansour', id: 101},
        uzbek_sadiq: {language: 175, author_name: 'Muhammad Sodik Muhammad Yusuf', id: 55},
        yoruba_mikail: {language: 183, author_name: 'Shaykh Abu Rahimah Mikael Aykyuni', id: 125},
        french_hameedullah: {language: 49, author_name: 'Muhammad Hamidullah', id: 31},
        nepali_central: {language: 116, author_name: 'Ahl Al-Hadith Central Society of Nepal', id: 108},
        persian_ih: {language: 43, author_name: 'IslamHouse', id: 135},
        persian_tagi: {language: 43, author_name: 'Dr. Husein Tagy Klu Dary', id: 29},
        spanish_garcia: {language: 40, author_name: 'Muhammad Isa Garcia', id: 83},
        spanish_montada_eu: {language: 40, author_name: 'Montada Islamic Foundation', id: 140},
        spanish_montada_latin: {language: 40, author_name: 'Noor International Center'},
        tajik_khawaja: {language: 160, author_name: 'Khawaja Mirof & Khawaja Mir', id: 139},
        tamil_baqavi: {language: 158, author_name: 'Abdul Hameed Baqavi', id: 133},
        uyghur_saleh: {language: 172, author_name: 'Shaykh Muhammad Saleh', id: 76},
        kurdish_bamoki: {language: 89, author_name: 'Muhammad Saleh Bamoki', id: 143},
        azeri_musayev: {language: 13, author_name: "Khan Mosaiv", id: 75},
        somali_abduh: {language: 150, author_name: "Muhammad Ahmad Abdi", id: 46},
        english_hilali_khan: {language: 38, author_name: 'Muhammad Taqi-ud-Din al-Hilali & Muhammad Muhsin Khan'},
        indonesian_sabiq: {language: 33, author_name: 'The Sabiq company'},
        english_rwwad: {language: 38, author_name: 'Ruwwad Center'},
        english_irving: {language: 38, author_name: "Muhammad Hijab"},
        german_aburida: {language: 33, author_name: "Abu Reda Muhammad ibn Ahmad"},
        italian_rwwad: {language: 74, author_name: "Othman al-Sharif"},
        turkish_rwwad: {language: 167, author_name: "Dar Al-Salam Center"},
        tagalog_rwwad: {language: 164, author_name: "Dar Al-Salam Center"},

        # only first 6 surah are available
        # georgian_rwwad: {language: 78, author_name: "Ruwwad Center"},
        bengali_zakaria: {language: 20, author_name: "Dr. Abu Bakr Muhammad Zakaria"},
        bosnian_rwwad: {language: 23, author_name: "Dar Al-Salam Center"},
        serbian_rwwad: {language: 152, author_name: "Dar Al-Salam Center"},
        albanian_rwwad: {language: 187, author_name: "Ruwwad Center"},
        ukrainian_yakubovych: {language: 173, author_name: "Dr. Mikhailo Yaqubovic"},
        japanese_saeedsato: {language: 76, author_name: "Saeed Sato"},
        korean_hamid: {language: 86, author_name: "Hamed Choi"},
        vietnamese_rwwad: {language: 177, author_name: "Ruwwad Center"},
        vietnamese_hassan: {language: 177, author_name: "Hasan Abdul-Karim"},
        kazakh_altai: {language: 82, author_name: "Khalifa Altay"},
        tajik_arifi: {language: 160, author_name: "Pioneers of Translation Center"},
        malayalam_kunhi: {language: 106, author_name: "Abdul-Hamid Haidar & Kanhi Muhammad"},
        gujarati_omari: {language: 56, author_name: "Rabila Al-Umry"},
        marathi_ansari: {language: 108, author_name: "Muhammad Shafi’i Ansari"},
        telugu_muhammad: {language: 159, author_name: "Maulana Abder-Rahim ibn Muhammad"},
        sinhalese_mahir: {language: 145, author_name: "Ruwwad Center"},
        tamil_omar: {language: 158, author_name: "Sheikh Omar Sharif bin Abdul Salam"},
        thai_complex: {language: 161, author_name: "Society of Institutes and Universities"},
        swahili_abubakr: {language: 157, author_name: "Dr. Abdullah Muhammad Abu Bakr and Sheikh Nasir Khamis"},
        luganda_foundation: {language: 95, author_name: "African Development Foundation"},
        hebrew_darussalam: {language: 59, author_name: "Dar Al-Salam Center"}
    }

    # ankobambara_foudi: {language: 164, author_name: ""},
    # dagbani_ghatubo: {language: 164, author_name: ""},
    # chichewa_betala: {language: 164, author_name: ""},

    translation_with_footnotes = [
        'albanian_nahi',
        'english_hilali_khan',
        'english_saheeh',
        'hausa_gummi',
        'hindi_omari',
        'indonesian_sabiq',
        'portuguese_nasr',
        'urdu_junagarhi',
        'uzbek_mansour',
        'uzbek_sadiq',
        'yoruba_mikail',
        'french_montada',
        'indonesian_affairs',
        'indonesian_complex',
        'spanish_garcia',
        'spanish_montada_eu',
        'tajik_khawaja',
        'spanish_montada_latin',
        # Custom
        'uyghur_saleh',
        'pashto_zakaria'
    ]

    data_source = DataSource.find_or_create_by(name: 'Quranenc', url: 'https://quranenc.com')

    footnote_regexp = {
        albanian_nahi: [/\[\d+\]/, /\[\d+\]/],
        indonesian_sabiq: [/[\*]+\(\d+\)/, /[\*]+\d+\)./],
        portuguese_nasr: [/\(\d+\)/, /\(\d+\)./],
        tajik_khawaja: [/\(\d+\)/, /\d+[.]/],
        spanish_montada_eu: [/\[\d+\]/, /\[\d+\]/],
        indonesian_complex: [/\d+/, /\d+[\.\s]/],
        indonesian_affairs: [/\d+\)/, /\*\d+\)/],
        french_montada: [/\[\d+\]/, /\[\d+\]/],
        english_hilali_khan: [/\[\d+\]/, /\[\d+\]/],
        english_saheeh: [/\[\d+\]/, /\[\d+\]-/],
        hausa_gummi: [/[\*]+/, /[\*]+/],
        hindi_omari: [/\[\d+\]/, /\d+./],
        urdu_junagarhi: [/[\*]+/, /[\*]+/],
        spanish_montada_latin: [/\[\d+\]/, /\[\d+\]/],
        uzbek_mansour: [],
        uzbek_sadiq: [],
        yoruba_mikail: [],
        spanish_garcia: []
    }

    custom_parsing = [
        'uyghur_saleh',
        'pashto_zakaria'
    ]

    resource_content_mapping.keys.each do |k|
      mapping = resource_content_mapping[k]
      language = Language.find(mapping[:language])

      resource = if mapping[:id] && ResourceContent.find_by_id(mapping[:id])
                   ResourceContent.find(mapping[:id])
                 else
                   author = Author.where(name: mapping[:author_name]).first_or_create

                   r = ResourceContent.where(
                       language: language,
                       data_source: data_source,
                       author_name: author.name,
                       author: author,
                       language_name: language.name.downcase,
                       cardinality_type: ResourceContent::CardinalityType::OneVerse,
                       sub_type: ResourceContent::SubType::Translation,
                       resource_type: ResourceContent::ResourceType::Content,
                   ).first_or_create

                   r.name = mapping[:author_name]
                   r.save
                   r
                 end

      Chapter.find_each do |c|
        url = "https://quranenc.com/en/api/translation/sura/#{k}/#{c.id}"

        puts "#{k} - #{c.id}"
        begin
          response = with_rescue_retry([RestClient::Exceptions::ReadTimeout], retries: 3, raise_exception_on_limit: true) do
            RestClient.get(url)
          end
        rescue RestClient::NotFound => e
          next
        end

        data = JSON.parse(response.body)['result']

        data.each do |ayah_data|
          verse = Verse.find_by(verse_key: "#{ayah_data['sura']}:#{ayah_data['aya']}")

          if translation_with_footnotes.include?(k.to_s)
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
                                                              }).first_or_initialize

            if footnote_resource_content.new_record?
              footnote_resource_content.save(validate: false)
            end

            if custom_parsing.include?(k.to_s)
              translation = if k.to_s == 'pashto_zakaria'
                              parse_pashto_zakaria(verse, ayah_data, resource)
                            elsif k.to_s == 'uyghur_saleh'
                              parse_uyghur_saleh(verse, ayah_data, resource)
                            end
            else
              reg = footnote_regexp[k]
              translation = create_translation_with_footnote(verse, ayah_data, resource, footnote_resource_content, reg[0], reg[1])
            end
          else
            text = fix_encoding(ayah_data['translation'])
            translation = create_translation(verse, text, resource)
          end

          translation.resource_name = resource.name
          translation.language = language
          translation.language_name = language.name.downcase
          translation.save
        end
      end

      resource.description = "#{resource.description} https://quranenc.com/en/browse/#{k}"
      resource.save
    end
  end

  task fix_sahih_international: :environment do
    priority = 3

    # English translation on top
    ResourceContent.translations.where.not(id: [131,149]).where(language_id: 38).each do |r|
      r.update priority: priority
      Translation.where(resource_content_id: r.id).update_all priority: priority

      priority += 1
    end

    # Urdu next
    ResourceContent.translations.where(language_name: 'urdu').each do |r|
      r.update priority: priority
      Translation.where(resource_content_id: r.id).update_all priority: priority

      priority += 1
    end

    ResourceContent.translations.where.not(id: [131,149], language_id: [38, 174]).each do |r|
      r.update priority: priority
      Translation.where(resource_content_id: r.id).update_all priority: priority

      priority += 1
    end



    PaperTrail.enabled = false
    admin = AdminUser.find_by_email('naveedahmada036@gmail.com')

    ResourceContent.translations.each do |r|
      count = Translation.where(resource_content_id: r.id).count
      if count != Verse.count
        r.update_column :approved, false
        ActiveAdmin::Comment.create(resource: r, author: admin, body: "Incomplete translation, disabling it. Translation count: #{count}")
      end
    end

    Translation.where(resource_content_id: 20).each do |t|
      text = t.text
      text = text.sub(/\(\s/, '').gsub('Allāh', 'Allah')

      t.update_column :text, text

      t.foot_notes.each do |f|
        t = f.text
        t = t.gsub('[-', '').gsub('Allāh', 'Allah')
        f.update_column :text, t
      end
    end

    langs = Translation.pluck(:language_id).uniq

    langs.each do |lang|
      language = Language.find(lang)
      language.update translations_count: ResourceContent.translations.one_verse.where(language_id: lang).size
    end

    TranslatedName.where(language_priority: nil).update_all language_priority: 2

    language = Language.find(38)
    ResourceContent.where(language: 38, priority: nil).update_all priority: 5
    ResourceContent.translations.where.not(language: 38).where(priority: nil).update_all priority: 5

    Translation.where(language_id: 38).where(priority: nil).update_all(priority: 5)

    Translation.where.not(language_id: 38).where(priority: nil).update_all(priority: 5)
    TranslatedName.where(language_id: 38).where(language_priority: nil).update_all(language_priority: 1)
    TranslatedName.where.not(language_id: 38).where(language_priority: nil).update_all(language_priority: 5)

    ResourceContent.find_each do |r|
      r.translated_names.where(language_id: language.id).first_or_create({
                                                                                   name: r.name,
                                                                                   language_name: language.name.downcase
                                                                               })
    end

    FootNote.find_each do |f|
      text = f.text
      text = text.sub('["*.', '').sub(/\*\./, '').strip

      if text.start_with? '. '
        text = text.delete_prefix '. '
      end
      f.update_column :text, text.sub('["*.', '').sub(/\*\./, '').strip
    end
  end
end