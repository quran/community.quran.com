ActiveAdmin.register Verse do
  searchable_select_options(scope: Verse.all,
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
  filter :text_madani
  filter :page_number
  filter :sajdah_number, as: :select, collection: proc { 1..14 }
  
  index do
    column :verse_number do |verse|
      link_to verse.id, admin_verse_path(verse)
    end
    column :chapter do |verse|
      link_to verse.chapter.id, admin_chapter_path(verse.chapter)
    end
    column :verse_number
    column :verse_key
    column :juz_number
    column :hizb_number
    column :sajdah_number
    column :page_number
    column :text_madani
  end
  
  show do
    attributes_table do
      row :id
      row :chapter do |object|
        link_to object.chapter_id, admin_chapter_path(object.chapter)
      end
      row :verse_number
      row :verse_index
      row :verse_key
      row :juz_number
      row :hizb_number
      row :rub_number
      row :page_number
      row :sajdah_number
      row :sajdah
      row :verse_lemma do |object|
        link_to_if object.verse_lemma, object.verse_lemma&.text_madani, [:admin, object.verse_lemma]
      end
      row :verse_stem do |object|
        link_to_if object.verse_stem, object.verse_stem&.text_madani, [:admin, object.verse_stem]
      end
      
      row :verse_root do |object|
        link_to_if object.verse_root, object.verse_root&.value, [:admin, object.verse_root]
      end
      
      row "Text madani(Imlaei script)" do |object|
        span class: 'quran-text me_quran' do
          object.text_imlaei
        end
      end

      row "Text madani(Uthmani script)" do |object|
        span class: 'quran-text me_quran' do
          object.text_madani
        end
      end

      row "Text Simple(Imlaei)" do |object|
        span class: 'quran-text' do
          object.text_simple
        end
      end

      row "Text Simple(Uthmani)" do |object|
        span class: 'quran-text' do
          object.text_uthmani_simple
        end
      end

      row :text_indopak do |object|
        span class: 'quran-text indopak' do
          object.text_indopak.to_s.html_safe
        end
      end

      row :v2_fonts do |object|
        span do
          object.words.order("position ASC").each do |w|
            span class: "v2p#{w.page_number} char-#{w.char_type_name.to_s.downcase}" do
              w.code.html_safe
            end
          end
        end
      end
      
      row :v3_fonts do |object|
        span do
          object.words.includes(:char_type).order("position ASC").each do |w|
            span class: "v3p#{w.page_number} char-#{w.char_type_name.to_s.downcase}" do
              w.code_v3.html_safe
            end
          end
        end
      end
      
      row :image do |object|
        image_tag object.image_url
      end
    end
    
    panel "Words" do
      table do
        thead do
          td "ID"
          td "Position"
          td "Code"
          td "Font v2"
          td "Font v3"
          td "Font (text v3)"
          td "Text(Imlaei)"
          td "Text(Uthmani)"
          td "Text(Imlaei Simple)"
          td "Text(Uthmani Simple)"
          td "Text(Indopak)"
          td "Char type"
        end
        
        tbody do
          verse.words.order("position ASC").each do |w|
            tr do
              td link_to(w.id, admin_word_path(w))
              
              td w.position
              
              td do
                "#{w.code_hex} - #{w.code}"
              end
              
              td class: 'quran-text' do
                span class: "v2p#{w.page_number} char-#{w.char_type_name.to_s.downcase}" do
                  w.code.html_safe
                end
              end
              
              td class: 'quran-text' do
                span class: "v3p#{w.page_number} char-#{w.char_type_name.to_s.downcase}" do
                  w.code_v3.html_safe
                end
              end
              
              td class: 'quran-text' do
                span class: "tp#{w.page_number} char-#{w.char_type_name.to_s.downcase}" do
                  w.text_imlaei
                end
              end
              
              td class: 'quran-text me_quran' do
                w.text_madani
              end
              
              td class: 'quran-text' do
                w.text_simple
              end

              td class: 'quran-text' do
                w.text_uthmani_simple
              end

              td class: 'quran-text row-text_indopak' do
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
                (link_to("play", "#_", class: 'play')+
                  audio_tag("", data: { url: "https://audio.qurancdn.com/#{file.url}" }, controls: true, class: 'audio')) if file.url
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
  
  controller do
    def find_resource
      scoped_collection.includes(:chapter, :media_contents, tafsirs: :resource_content, translations: :resource_content, audio_files: :recitation).find(params[:id]) # prevents N+1 queries to your database
    end
  end
end
