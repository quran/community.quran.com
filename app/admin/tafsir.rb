ActiveAdmin.register Tafsir do
  menu parent: "Content"
  actions :all, except: :destroy
  ActiveAdminViewHelpers.versionate(self)

  permit_params do
    [:text, :verse_id, :language_name, :language_id, :resource_content_id, :resource_name, :verse_key]
  end
  
  filter :verse_id
  filter :language

  index do
    id_column

    column :language do |resource|
      link_to resource.language_name, admin_language_path(resource.language_id)
    end

    column :verse do |resource|
      link_to resource.verse_id, admin_verse_path(resource.verse_id)
    end

    column :name do |resource|
      link_to resource.resource_content.name, [:admin, resource.resource_content]
    end
  end
  
  show do
  
    attributes_table do
      row :id
      row :verse
      row :language
      row :verse_key
      row :resource_content
      row :text
    end
    
    if params[:version]
      ActiveAdminViewHelpers.diff_panel(self, resource)
    end
  end
end
