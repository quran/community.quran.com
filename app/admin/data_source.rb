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
end
