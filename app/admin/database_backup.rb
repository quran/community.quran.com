ActiveAdmin.register DatabaseBackup do
  menu parent: "Settings"
  
  filter :database_name
  filter :created_at
  filter :tag
  
  index do
    id_column
    column :database_name
    
    column :created_at
    column :tag
    column :size
    column :download do |backup|
      link_to "Download", backup.file.url
    end
  end

  permit_params do
    [:database_name, :tag]
  end
end
