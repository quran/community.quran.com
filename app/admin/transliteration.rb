ActiveAdmin.register Transliteration do
  menu parent: "Content"
  actions :all, except: :destroy
  ActiveAdminViewHelpers.versionate(self)
  
  filter :language
  filter :resource_type, as: :select, collection: ['Verse', 'Word']
  filter :resource_id

  show do
    attributes_table do
      row :id
      row :text
      row :language
      row :resource
      row :resource_content
    end

    if params[:version]
      ActiveAdminViewHelpers.diff_panel(self, resource)
    end
    row :created_at
    row :updated_at
  end
  
  permit_params do
    [:language_id, :resource_type, :resource_id, :text, :language_name, :resource_content_id]
  end
  
  index do
    id_column
    
    column :language do |resource|
      link_to resource.language_name, admin_language_path(resource.language_id)
    end
    
    column :resource_type

    column :text
    
    actions
  end
  
  form do |f|
    f.inputs "Transliteration Detail" do
      f.input :text
      f.input :language
      f.input :resource_content
      f.input :language_name
      f.input :resource_id
      f.input :resource_type, as: :select, collection: ['Verse', 'Word']
    end
    f.actions
  end
end
