ActiveAdmin.register ChapterInfo do
  menu parent: "Content", priority: 3
  actions :all, except: :destroy
  ActiveAdminViewHelpers.versionate(self)

  filter :chapter, as: :searchable_select,
         ajax: {resource: Chapter}

  filter :language, as: :searchable_select,
         ajax: {resource: Language}

  permit_params do
    [:text, :language_name, :language_id, :source, :short_text]
  end

  index do
    column :id do |resource|
      link_to(resource.id, [:admin, resource])
    end

    column :language do |resource|
      link_to resource.language_name, admin_language_path(resource.language_id) if resource.language_id
    end

    column :chapter do |resource|
      link_to resource.chapter_id, admin_chapter_path(resource.chapter_id)
    end

    actions
  end

  show do
    attributes_table do
      row :id
      row :chapter do |object|
        link_to object.chapter_id, admin_chapter_path(object.chapter)
      end
      row :text do |resource|
        div class: resource.language_name do
          resource.text.to_s.html_safe
        end
      end
      row :short_text
      row :language
      row :resource_content
    end

    if params[:version]
      ActiveAdminViewHelpers.diff_panel(self, resource)
    end
  end

  form do |f|
    f.inputs "Chapter Info Details" do
      f.input :chapter,
              as: :searchable_select,
              ajax: {resource: Chapter}

      f.input :language,
              as: :searchable_select,
              ajax: {resource: Language}

      f.input :resource_content,
              as: :searchable_select,
              ajax: {resource: ResourceContent}

      f.input :source
      f.input :short_text
      f.input :text, as: :froala_editor
    end
    f.actions
  end
end
