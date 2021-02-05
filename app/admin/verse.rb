ActiveAdmin.register Verse do
  searchable_select_options(scope: Verse,
                            text_attribute: :verse_key
  )
  menu parent: "Quran", priority: 2
  ActiveAdminViewHelpers.versionate(self)

  actions :all, except: [:destroy, :new]

  filter :chapter_id
  filter :verse_number
  filter :verse_index
  filter :verse_key
  filter :juz_number
  filter :hizb_number
  filter :rub_number
  filter :sajdah
  filter :text_uthmani
  filter :page_number
  filter :sajdah_number, as: :select, collection: proc { 1..14 }

  index do
    column :verse_number do |verse|
      link_to verse.id, admin_verse_path(verse)
    end
    column :chapter do |verse|
      link_to verse.chapter_id, admin_chapter_path(verse.chapter_id)
    end
    column :verse_number
    column :verse_key
    column :juz_number
    column :hizb_number
    column :sajdah_number
    column :page_number
    column :text_uthmani
  end

  show do
    render 'shared/page_font', verses: [resource]

    attributes_table do
      row :id
      row :chapter do
        link_to resource.chapter_id, admin_chapter_path(resource.chapter_id)
      end
      row :verse_number
      row :verse_index
      row :verse_key
      row :juz_number
      row :hizb_number
      row :rub_number
      row :page_number
      row :sajdah_number
      row :sajdah_type

      row :verse_lemma do
        link_to_if resource.verse_lemma, resource.verse_lemma&.text_madani, [:admin, resource.verse_lemma]
      end

      row :verse_stem do
        link_to_if resource.verse_stem, resource.verse_stem&.text_madani, [:admin, resource.verse_stem]
      end

      row :verse_root do
        link_to_if resource.verse_root, resource.verse_root&.value, [:admin, resource.verse_root]
      end

      row "Imlaei script" do
        div class: 'quran-text me_quran' do
          resource.text_imlaei
        end
      end

      row "Imlaei Simple" do
        div class: 'quran-text me_quran' do
          resource.text_imlaei_simple
        end
      end

      row "Text Uthmani" do
        div class: 'quran-text me_quran' do
          resource.text_uthmani
        end
      end

      row "Uthmani Simple" do
        div class: 'quran-text me_quran' do
          resource.text_uthmani_simple
        end
      end

      row "Uthmani Simple Tajweed" do
        div class: 'quran-text me_quran' do
          resource.text_uthmani_tajweed.to_s.html_safe
        end
      end

      row :text_indopak do
        div class: 'quran-text indopak' do
          resource.text_indopak.to_s.html_safe
        end
      end

      row :text_indopak do
        div class: 'quran-text indopak' do
          resource.text_indopak.to_s.html_safe
        end
      end

      row :v1_code do
        div class: "quran-text p#{resource.page_number}-v1" do
          resource.code_v1
        end
      end

      row :v2_code do
        div class: "quran-text p#{resource.page_number}-v2" do
          resource.code_v2
        end
      end

      row :image do
        div class: "quran-text" do
          image_tag resource.image_url
        end
      end

      row :created_at
      row :updated_at
    end

    panel "Words" do
      table do
        thead do
          td "ID"
          td "Position"
          td "Code v1"
          td "Code v2"
          td "Uthmani"
          td "Uthmani Simple"
          td "Imlaei"
          td "Imlaei Simple"
          td "Indopak"
          td "Char type"
        end

        tbody class: 'quran-text' do
          verse.words.order("position ASC").each do |w|
            tr do
              td link_to(w.id, admin_word_path(w))
              td w.position

              td class: "p#{w.page_number}-v1" do
                w.code_v1
              end

              td class: "p#{w.page_number}-v2" do
                w.code_v2
              end

              td class: 'me_quran' do
                w.text_uthmani
              end

              td class: 'me_quran' do
                w.text_uthmani_simple
              end

              td class: 'me_quran' do
                w.text_imlaei
              end

              td class: 'me_quran' do
                w.text_imlaei_simple
              end

              td class: 'indopak' do
                w.text_indopak
              end

              td w.char_type_name
            end
          end
        end
      end
    end

    panel "Available Recitations(#{verse.audio_files.size})" do
      table do
        thead do
          td "ID"
          td "Reciter"
          td "Recitation style"
          td "Duration"
          td "Audio"
        end

        tbody do
          verse.audio_files.each do |file|
            tr do
              td link_to(file.id, admin_audio_file_path(file))
              td file.recitation.reciter_name
              td file.recitation.style
              td file.duration
              td do
                (link_to("play", "#_", class: 'play') +
                    audio_tag("", data: {url: "https://audio.qurancdn.com/#{file.url}"}, controls: true, class: 'audio')) if file.url
              end
            end
          end
        end
      end
    end

    panel "Translations(#{verse.translations.size})", class: 'scrollable' do
      table do
        thead do
          td "ID"
          td "Language"
          td "Text"
        end

        tbody do
          verse.translations.each do |trans|
            tr do
              td link_to(trans.id, admin_translation_path(trans))
              td "#{trans.language_name}-#{trans.resource_content.name}"
              td do
                div class: "#{trans.language_name} translation" do
                  trans.text.html_safe
                end
              end
            end
          end
        end
      end
    end

    if params[:version]
      ActiveAdminViewHelpers.diff_panel(self, resource)
    end
  end

  sidebar "Media content", only: :show do
    table do
      thead do
        td :id
        td :language
        td :author
      end

      tbody do
        resource.media_contents.each do |c|
          tr do
            td link_to(c.id, [:admin, c])
            td c.language_name
            td c.resource_content.author_name
          end
        end
      end
    end
  end

  sidebar "Tafsirs", only: :show do
    table do
      thead do
        td :id
        td :name
        td :language
        td :author
      end

      tbody do
        resource.tafsirs.each do |c|
          tr do
            td link_to(c.id, [:admin, c])
            td c.resource_content.name
            td c.language_name
            td c.resource_content.author_name
          end
        end
      end
    end
  end

  permit_params do
    [:text_uthmani, :text_uthmani_simple, :text_uthmani_simple]
  end

  controller do
    def find_resource
      collection = scoped_collection
                       .includes(
                           :chapter,
                           :media_contents,
                           tafsirs: :resource_content,
                           translations: :resource_content,
                           audio_files: :recitation
                       )

      if params[:id].include?(':')
        collection.find_by_verse_key(params[:id])
      else
        collection.find(params[:id])
      end
    end
  end
end
