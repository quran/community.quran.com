ActiveAdmin.register Word do
  menu parent: "Quran", priority: 3
  actions :all, except: :destroy
  ActiveAdminViewHelpers.versionate(self)

  filter :verse_key
  filter :char_type
  filter :page_number
  filter :text_madani
  filter :text_simple
  filter :code_hex

  permit_params do
    [:verse_id, :position, :text_madani, :text_indopak, :text_simple, :verse_key, :page_number, :class_name, :line_number, :code_dec, :code_hex,
     :code_hex_v3, :code_dec_v3, :char_type_id, :audio_url, :location, :char_type_name
    ]
  end

  form do |f|
    f.inputs "Word detail" do
      f.input :verse_id
      f.input :position
      f.input :text_madani, as: :text
      f.input :text_indopak, as: :text
      f.input :text_simple, as: :text
      f.input :verse_key
      f.input :page_number
      f.input :class_name
      f.input :line_number
      f.input :code_dec
      f.input :code_hex
      f.input :code_hex_v3
      f.input :code_dec_v3
      f.input :char_type
      f.input :audio_url
      f.input :location
      f.input :char_type_name, as: :select, collection: CharType.pluck(:name)
    end
    f.actions
  end

  show do
    attributes_table do
      row :id
      row :verse
      row :verse_key
      row :verse_index
      row :position
      row :text_uthmani do
        span resource.text_uthmani, class: 'me_quran'
      end
      row :text_uthmani_simple do
        span resource.text_uthmani_simple, class: 'me_quran'
      end
      row :text_imlaei do
        span resource.text_imlaei, class: 'me_quran'
      end
      row :text_imlaei_simple do
        span resource.text_imlaei_simple, class: 'me_quran'
      end
      row :text_indopak do
        span resource.text_indopak, class: 'indopak'
      end

      row :page_number do |resource|
        link_to resource.page_number, "/admin/page?page#{resource.page_number}"
      end

      row :font do |resource|
        (span class: "v2p#{resource.page_number} char-#{resource.char_type_name.to_s.downcase}" do
          resource.code.html_safe
        end)
      end

      row :font_v3 do |resource|
        (span class: "v3p#{resource.page_number} char-#{resource.char_type_name.to_s.downcase}" do
          resource.code_v3.html_safe
        end)
      end

      row :text_font do |resource|
        (span class: "pt#{resource.page_number} char-#{resource.char_type_name.to_s.downcase}" do
          resource.code_v3.html_safe
        end)
      end

      row :image do |resource|
        # image_tag resource.image_url if resource.image_url
      end

      row :image_blob
      row :word_corpus
      row :word_lemma
      row :synonyms do |resource|
        resource.synonyms.each do |s|
          span do
            link_to s.text, [:admin, s], class: 'ml-2'
          end
        end
        nil
      end
    end

    active_admin_comments

    if params[:version]
      ActiveAdminViewHelpers.diff_panel(self, resource)
    end
  end

  index do
    column :id do |resource|
      link_to resource.id, admin_word_path(resource)
    end

    column :verse do |resource|
      link_to resource.verse_id, admin_verse_path(resource.verse_id)
    end

    column :char_type do |resource|
      resource.char_type_name
    end
    column :position

=begin
    column :pause_name do |resource|
      if resource.char_type_id == 4
        if resource.pause_marks.present?
          resource.pause_marks.pluck(:mark).join ', '
        else
          div do
            (link_to("Jeem", admin_pause_marks_path(word_id: resource.id, mark: 'jeem'), class: 'mark-btn', data: {method: :post, remote: true, disable_with: 'Wait'}) +
                (link_to "Sad lam ya", admin_pause_marks_path(word_id: resource.id, mark: 'Sad lam ya'), class: 'mark-btn', data: {method: :post, remote: true, disable_with: 'Wait'})+
                (link_to "Three dots", admin_pause_marks_path(word_id: resource.id, mark: 'Three dots'), class: 'mark-btn', data: {method: :post, remote: true, disable_with: 'Wait'})+
                (link_to "Qaf lam ya", admin_pause_marks_path(word_id: resource.id, mark: 'qaf lam ya'), class: 'mark-btn', data: {method: :post, remote: true, disable_with: 'Wait'})+
                (link_to "Lam Alif", admin_pause_marks_path(word_id: resource.id, mark: 'lam alif'), class: 'mark-btn', data: {method: :post, remote: true, disable_with: 'Wait'})+
                (link_to "Meem", admin_pause_marks_path(word_id: resource.id, mark: 'Meem'), class: 'mark-btn', data: {method: :post, remote: true, disable_with: 'Wait'})+
                (link_to "Seen", admin_pause_marks_path(word_id: resource.id, mark: 'Seen'), class: 'mark-btn', data: {method: :post, remote: true, disable_with: 'Wait'})
            ).html_safe
          end
        end
      end
    end
=end

    column :font do |resource|
      (span class: "v2p#{resource.page_number} char-#{resource.char_type.name.to_s.downcase}" do
        resource.code.html_safe
      end)
    end

    column :fontv3 do |resource|
      (span class: "v3p#{resource.page_number} char-#{resource.char_type.name.to_s.downcase}" do
        resource.code_v3.html_safe
      end)
    end

    column :text_font do |resource|
      (span class: "tp#{resource.page_number} char-#{resource.char_type_name.to_s.downcase}" do
        resource.text_madani
      end)
    end

    column :text_madani
    column :text_simple
    column :text_imlaei

    actions
  end

  def scoped_collection
    super.includes :verse, :char_type # prevents N+1 queries to your database
  end

  sidebar "Audio", only: :show do
    table do
      thead do
        td :id
        td :play
      end

      tbody do
        tr do
          td do
            (link_to("play", "#_", class: 'play') +
                audio_tag("", data: {url: "//audio.qurancdn.com/#{word.audio_url}"}, controls: true, class: 'audio')) if word.audio_url
          end
        end
      end
    end
  end

  sidebar "Transliterations", only: :show do
    table do
      thead do
        td :id
        td :language
        td :text
      end

      tbody do
        word.transliterations.each do |trans|
          tr do
            td link_to(trans.id, [:admin, trans])
            td link_to(trans.language_name, admin_language_path(trans.language_id)) if trans.language_id
            td trans.text
          end
        end
      end
    end
  end

  sidebar "Translations", only: :show do
    table do
      thead do
        td :id
        td :language
        td :text
      end

      tbody do
        word.word_translations.each do |trans|
          tr do
            td link_to(trans.id, [:admin, trans])
            td link_to(trans.language_name, admin_language_path(trans.language_id)) if trans.language_id
            td trans.text
          end
        end
      end
    end
  end

  collection_action :export_sqlite, method: 'put' do
    file_path = ExportWordsJob.new.perform(params[:name])

    send_file file_path
  end
end
