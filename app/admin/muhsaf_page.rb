ActiveAdmin.register MuhsafPage do
  menu parent: "Quran", priority: 6
  actions :all, except: [:destroy, :new]

  index do
    id_column

    column :first_verse_id
    column :last_verse_id
    column :verses_count

    actions
  end
end
