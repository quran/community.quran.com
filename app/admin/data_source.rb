ActiveAdmin.register DataSource do
  menu parent: "Settings"
  actions :all, except: :destroy
  permit_params :name, :url, on: :data_source
 
  sidebar "Resources", only: :show do
    table do
      thead do
        td :id
        td :name
        td :language
      end
    
      tbody do
        resource.resource_contents.each do |c|
          tr do
            td link_to(c.id, [:admin, c])
            td c.name
            td c.language_name
          end
        end
      end
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
