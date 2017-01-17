ActiveAdmin.register Translation do
  menu parent: "Content"

  filter :language
  filter :resource_type, as: :select, collection: ['Verse', 'Word']
  filter :resource_id
  filter :resource_content, as: :select, collection: -> do ResourceContent.where(sub_type: ResourceContent::SubType::Translation) end

  index do
    column :id do |resource|
      link_to(resource.id, [:admin, resource])
    end
    column :language do |resource|
      resource.language_name
    end
    column :resource_type
    column :resource_id do |resource| resource.resource_id end
    actions
  end

  show do
    attributes_table do
      row :id
      row :resource
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
end
