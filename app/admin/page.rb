ActiveAdmin.register_page "Page" do
  menu parent: "Quran"

  action_item :previous_page do
    page = params[:page].to_i
    page = page > 1 ? page - 1 : 1
    link_to "Previous page", "/admin/page?page=#{page}", class: "btn"
  end

  action_item :next_page do
    page = params[:page].to_i
    page = page < 604 ? page + 1 : 604

    link_to "Next page", "/admin/page?page=#{page}", class: "btn"
  end

  content do
    page = params[:page].to_i

    verses = Verse.includes(:words).where(page_number: page).order("verse_number ASC")
    panel "Page verses" do
      table do
        thead do
          td 'Verse'
          td 'V2 font'
          td 'V3 font'
          td 'Text font'
        end

        tbody do
          verses.each do |verse|
            tr do
              td class: 'quran-text me_quran' do
                link_to verse.text_madani, admin_verse_path(verse)
              end

              td do
                span do
                  verse.words.order("position ASC").each do |w|
                    span class: "v2p#{w.page_number} char-#{w.char_type_name.to_s.downcase}" do
                      w.code.html_safe
                    end
                  end
                end
              end

              td do
                span do
                  verse.words.order("position ASC").each do |w|
                    span class: "v3p#{w.page_number} char-#{w.char_type_name.to_s.downcase}" do
                      w.code_v3.html_safe
                    end
                  end
                end
              end

              td do
                span do
                  verse.words.order("position ASC").each do |w|
                    span class: "tp#{w.page_number} char-#{w.char_type_name.to_s.downcase}" do
                      w.text_madani
                    end
                  end
                end
              end
            end
          end
        end
      end
    end
  end
end