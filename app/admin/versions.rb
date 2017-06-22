ActiveAdmin.register PaperTrail::Version, as: 'ContentChanges' do
  menu parent: 'Content'
  
  actions :all, except: [:new, :edit]
  
  filter :id
  filter :event
  filter :create_at
  filter :whodunnit
  filter :item_type
  
  index do
    id_column
  
    column :item do |resource|
      link_to resource.item_type.underscore.humanize, [:admin, resource.item, version: resource.id]
    end
  
    column :event
    column :created_at
  end
end