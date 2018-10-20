ActiveAdmin.register DatabaseBackup do
  menu parent: "Settings"
  
  filter :database_name
  filter :created_at
  
  index do
    id_column
    column :database_name
    
    column :created_at
    column :size
    column :download do |backup|
      link_to "Download", backup.file.url
    end
  end
end
