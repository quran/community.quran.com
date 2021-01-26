ActiveAdmin.register MediaContent do
  menu parent: "Media", priority: 2
  actions :all, except: :destroy

  show do
    attributes_table do
      row :id
      row :resource
      row :language
      row :url

      row :embed_text do |resource|
       p resource.embed_text.to_s.html_safe
      end
      row :created_at
      row :updated_at
    end
  end

  index do
    column :id
    column :author_name
    column :resource_content
    column :language
    actions
  end

  def scoped_collection
    super.includes :language, :resource_content
  end
end
