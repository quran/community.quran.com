ActiveAdmin.register Translation do
  menu parent: "Content"
  actions :all, except: :destroy
  
  ActiveAdminViewHelpers.versionate(self)
  
  filter :language
  filter :verse_id
  filter :resource_content, as: :select, collection: -> do
    ResourceContent.where(sub_type: ResourceContent::SubType::Translation)
  end
  
  index do
    column :id do |resource|
      link_to(resource.id, [:admin, resource])
    end
    column :language do |resource|
      resource.language_name
    end
    column :verse_id do |resource|
      link_to resource.verse_id, admin_verse_path(resource.verse_id)
    end

    actions
  end
  
  show do
    attributes_table do
      row :id
      row :verse
      row :language
      row :priority

      row :text do |resource|
        div class: resource.language_name.to_s.downcase do
          resource.text.html_safe
        end
      end
      row :resource_content
    end
    
    if params[:version].to_i > 0
      ActiveAdminViewHelpers.diff_panel(self, resource)
    end

    active_admin_comments
  end
  
  def scoped_collection
    super.includes :language # prevents N+1 queries to your database
  end
  
  permit_params do
    [:language_id, :verse_id, :text, :language_name, :resource_content_id]
  end
  
  form do |f|
    f.inputs "Translation Detail" do
      f.input :text, as: :text
      f.input :language
      f.input :language_name
      f.input :resource_content_id
      f.input :verse_id
    end

    f.actions
  end
  
  collection_action :import_translation, method: 'post' do
    success, resource = Translation.import_translations(params[:import])
    if success
      redirect_to [:admin, resource], notice: 'Translation is imported successfully'
    else
      redirect_to :back, alert: "Sorry can't import this translation, error: #{resource}"
    end
  end
  
  sidebar "Import translation", only: :index do
    div do
      semantic_form_for "import", url: import_translation_admin_translations_path, method: 'post' do |form|
        form.input(:author_id, as: :select, collection: Author.pluck(:name, :id), hint: "Select author OR add new #{link_to "add new", "/admin/authors/new"}".html_safe) +
          form.input(:language_id, as: :select, collection: Language.pluck(:name, :id), hint: "Select language of this translation", required: true) +
          form.input(:data_source_id, as: :select, collection: DataSource.pluck(:name, :id), hint: "Select data source OR add new #{link_to "add new", "/admin/data_sources/new"}".html_safe) +
          form.input(:file, as: :file, hint: "Select translation file, must be txt file and translation of each verse in one line") +
          form.submit("Import", data: { disable_with: 'Importing...' })
      end
    end
  end
end
