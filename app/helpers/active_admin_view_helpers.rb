module ActiveAdminViewHelpers
  class << self
    def versionate(context)
      context.controller do
        def original_resource
          scoped_collection.find(params[:id])
        end
        
        def find_resource
          item = scoped_collection.includes(:versions).find(params[:id])
          
          if params[:version]
            item.versions.find(params[:version]).reify
          else
            item
          end
        end
      end
      
      context.sidebar "Versions", only: :show do
        div do
          h2 "Current version #{link_to resource.versions.size}".html_safe
          
          table do
            thead do
              td :version
              td :created_at
              td :user
            end
            
            tbody do
              resource.versions.each_with_index do |version, index|
                tr do
                  td link_to index, version: version.id
                  td l(version.created_at, format: :short)
                  td AdminUser.find_by_id(version.whodunnit).try(:email)
                end
              end
            end
          end
        end
      end
    end
    
    def render_translated_name_sidebar(context)
      context.sidebar "Translated names", only: :show do
        div do
          semantic_form_for [:admin, TranslatedName.new] do |form|
            form.input(:resource_id, as: :hidden, input_html: { value: resource.id }) +
              form.input(:resource_type, value: 'Author', as: :hidden, input_html: { value: resource.class.to_s }) +
              form.inputs(:name, :language) +
              form.actions(:submit)
          end
        end
        
        table do
          thead do
            td :id
            td :language
            td :name
          end
          
          tbody do
            resource.translated_names.each do |translated_name|
              tr do
                td link_to(translated_name.id, [:admin, translated_name])
                td translated_name.language_name
                td translated_name.name
              end
            end
          end
        end
      end
    end
  end
end
