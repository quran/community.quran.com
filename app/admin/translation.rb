ActiveAdmin.register Translation do
  menu parent: "Content"
  
  filter :language
  filter :resource_type, as: :select, collection: ['Verse', 'Word']
  filter :resource_id
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
    column :resource_type
    column :resource_id do |resource|
      resource.resource_id
    end
    actions
  end
  
  show do
    attributes_table do
      row :id
      row :resource
      row :language
      row :text do |resource|
        div class: resource.language_name.to_s.downcase do
          resource.text
        end
      end
      row :resource_content
    end
  end
  
  def scoped_collection
    super.includes :language # prevents N+1 queries to your database
  end
  
  permit_params do
    [:language_id, :resource_type, :resource_id, :text]
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
        form.submit("Import", data: {disable_with: 'Importing...'})
      end
    end
  end
end
