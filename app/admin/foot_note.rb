ActiveAdmin.register FootNote do
  menu parent: "Content"
  actions :all, except: :destroy
  ActiveAdminViewHelpers.versionate(self)

  filter :language
  filter :language
  filter :resource_type, as: :select, collection: ['Translation']
  filter :resource_id

  show do
  
    attributes_table do
      row :id
      row :resource
      row :language
      row :resource_content
      row :text
    end
  
    if params[:version]
      ActiveAdminViewHelpers.diff_panel(self, resource)
    end
  end
# See permitted parameters documentation:
# https://github.com/activeadmin/activeadmin/blob/master/docs/2-resource-customization.md#setting-up-strong-parameters
#
# permit_params :list, :of, :attributes, :on, :model
#
# or
#
# permit_params do
#   permitted = [:permitted, :attributes]
#   permitted << :other if params[:action] == 'create' && current_user.admin?
#   permitted
# end


end
