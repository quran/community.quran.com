ActiveAdmin.register Lemma do
  menu parent: "Data"
  actions :all, except: :destroy

  filter :text_clean

  show do
    attributes_table do
      row :id
      row :text_clean
      row :text_madani
      row :created_at
      row :updated_at
    end

    panel "Ayahs for this lemma" do
      attributes_table_for lemma do
        words_ids = lemma.words.pluck(:id)
        lemma.verses.includes(:words).each do |verse|

          row verse.verse_key do
            div class: 'quran-text me_quran' do
              link_to(verse.verse_key, admin_verse_path(verse)) +
                  verse.words.map do |word|
                    if words_ids.include?(word.id)
                      "<success>#{word.text_uthmani}</success>"
                    else
                      "<span>#{word.text_uthmani}</span>"
                    end
                  end.join(' ').html_safe
            end
          end
        end
      end
    end
  end
end