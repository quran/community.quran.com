ActiveAdmin.register ImportantNote do
  menu parent: "Notes"
  actions :all, except: :destroy

  permit_params do
    [:name, :url]
  end

  show do
    attributes_table do
      row :id
      row :user
      row :text
      row :chapter_id
      row :verse_id
      row :word_id
      row :created_at
      row :updated_at
    end

    active_admin_comments
  end
end
