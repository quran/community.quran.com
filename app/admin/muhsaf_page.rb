ActiveAdmin.register MuhsafPage do
  menu parent: "Quran", priority: 6
  actions :all, except: [:destroy, :new]

  index do
    id_column
    column :page_number do |page|
      link_to page.page_number, "/admin/page?page=#{page.page_number}", class: "btn"
    end
    column :first_verse_id
    column :last_verse_id
    column :verses_count

    actions
  end
end
