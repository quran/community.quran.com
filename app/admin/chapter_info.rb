ActiveAdmin.register ChapterInfo do
  menu parent: "Content", priority: 3

  filter :chapter, as: :select, collection: 1..114
  filter :language

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
      row :text do |resource| div class: resource.language_name do resource.text.to_s.html_safe end end
      row :short_text
      row :language
      row :resource_content
    end
  end
end
