namespace :ibne_kathir do
  task import: :environment do
    def is_blank?(node)
      (node.text? && node.content.strip.blank?) || (node.element? && node.name == 'br')
    end

    def all_children_are_blank?(node)
      node.children.all? { |child| is_blank?(child) }
    end

    def remove_empty_dom(dom)
      dom.search('br').remove
      dom.search('p').find_all { |p| all_children_are_blank?(p) }.each do |p|
        p.remove
      end

      dom
    end

    def fetch_surah_info(surah_num)
      url = "http://www.alim.org/library/quran/AlQuran-tafsir/TIK/#{surah_num}/0"

      response = with_rescue_retry([RestClient::Exceptions::ReadTimeout], retries: 3, raise_exception_on_limit: true) do
        RestClient.get(url)
      end

      if response && 200 == response.code
        docs = Nokogiri.parse(response.body)

        info = docs.search(".field-content note")

        format_tafsir_text(info)
      end
    end

    def format_tafsir_text(text)
      text = remove_empty_dom(text)

      text.search("div.title").each do |t|
        t.name = 'h2'
      end

      text.search(".arabic_text_style").each do |t|
        t.remove_attribute 'dir'
        t.remove_attribute 'align'
      end

      text.inner_html.to_s.gsub('arabic_text_style', 'text_uthmani arabic').gsub(/\n\t*/, '').gsub(/﴿|﴾/, '')
    end

    PaperTrail.enabled = false

    tafsir_name = "Tafsir Ibn Kathir"
    language = Language.find_by(name: 'English')

    data_source = DataSource.where(name: 'http://www.alim.org/', url: 'http://www.alim.org/library/quran/AlQuran-tafsir/TIK/1/0').first_or_create

    tafsir_resource_content = ResourceContent.where(
      name: tafsir_name,
      cardinality_type: ResourceContent::CardinalityType::OneVerse,
      resource_type: ResourceContent::ResourceType::Content,
      sub_type: ResourceContent::SubType::Tafsir,
      language: language,
      author_id: 158,
      author_name: 'Hafiz Ibn Kathir',
      data_source: data_source,
      language_name: 'english',
      priority: 3,
      slug: 'en-tafisr-ibn-kathir'
    ).first_or_create

    #Tafsir.where(resource_content: tafsir_resource_content).delete_all

    Verse.unscoped.order('verse_index asc').each do |verse|
      tafsir = Tafsir.where(verse_id: verse.id, resource_content_id: tafsir_resource_content.id).first_or_initialize
      puts verse.verse_key

      next if tafsir.persisted?

      url = "http://www.alim.org/library/quran/AlQuran-tafsir/TIK/#{verse.verse_key.gsub(':', '/')}"

      response = with_rescue_retry([RestClient::Exceptions::ReadTimeout], retries: 3, raise_exception_on_limit: true) do
        RestClient.get(url)
      end

      if response && 200 == response.code
        docs = Nokogiri.parse(response.body)

        tafsir_text = docs.search(".field-content note")

        if tafsir_text.present?
          tafsir.language = language
          tafsir.language_name = 'english'
          tafsir.resource_name = tafsir_name

          text = format_tafsir_text(tafsir_text)

          if 1 == verse.verse_number
            text = "#{fetch_surah_info(verse.chapter_id)} #{text}"
          end

          tafsir.text = text
          tafsir.save
        end
      end
    end
  end
end