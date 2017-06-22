ActiveAdmin.register PaperTrail::Version, as: 'ContentChanges' do
  menu parent: 'Content'
  
  actions :all, except: [:new, :edit, :destroy]
  
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
  
  action_item :show, only: :show do
    link_to "Next version", "/admin/content_changes/#{resource.next.id}" if resource.next
  end
  
  action_item :show, only: :show do
    link_to "Previous version", "/admin/content_changes/#{resource.previous.id}" if resource.previous
  end
  
  action_item :show, only: :show do
    link_to revert_admin_content_change_path(resource.id), method: :put, data: { confirm: "Are you sure?" } do
      "Revert #{resource.item_type} to this version!"
    end
  end
  
  member_action :revert, method: 'put' do
    item = resource.reify
    item.save
   
    redirect_to  [:admin, item], notice: 'Reverted successfully!'
  end
  
  show do
    attributes_table "Version details" do
      row :id
      row :item_type do
        link_to resource.item_type, [:admin, resource.item, version: resource.index]
      end
      row :event
      row :user do
        link_to AdminUser.find_by_id(resource.whodunnit).try(:email), [:admin, AdminUser.find_by_id(resource.whodunnit)] rescue "Unknown"
      end
      row :created_at
    end
    
    panel "Attributes of #{resource.item_type} at this version" do
      current = resource.reify
      attributes_table_for current do
        current.attributes.each do |key, val|
          row key do
            current.send(key).to_s.html_safe
          end
        end
      end
    end
    
    panel "Changes diff for this version" do
      if previous = resource.previous
        previous = previous.reify
        current  = resource.reify
        
        attributes_table_for previous do
          current.attributes.each do |key, val|
            row key do
              diff = Diffy::Diff.new(previous.send(key).to_s, val.to_s, allow_empty_diff: false).to_s(:html).html_safe
              diff.present? ? diff : val
            end
          end
        end
      end
    end
  end
end