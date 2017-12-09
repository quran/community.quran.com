module ActiveAdminViewHelpers
  class << self
    def diff_panel(context, resource)
      context.panel "Changes diff for this version" do
        previous = resource.paper_trail.previous_version
        previous = previous
        current  = resource
        
        context.attributes_table_for previous do
          current.attributes.each do |key, val|
            context.row key do
              diff = Diffy::Diff.new(previous.try(key).to_s, val.to_s, allow_empty_diff: false).to_s(:html).html_safe
              diff.present? ? diff : val
            end
          end
        end
      end
    end
    
    def versionate(context)
      context.controller do
        def original_resource
          scoped_collection.find(params[:id])
        end
        
        def find_resource
          item = scoped_collection.includes(:versions).find(params[:id])
          
          if params[:version].to_i > 0
            item.versions[params[:version].to_i].reify
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
              td :changes
              td :created_at
              td :user
            end
            
            tbody do
              (resource.versions.size - 1).downto(0) do |index|
                version = resource.versions[index]
                tr do
                  td link_to index, version: version.index
                  td link_to index, "/admin/content_changes/#{version.id}"
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
