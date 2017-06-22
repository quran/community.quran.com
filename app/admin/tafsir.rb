ActiveAdmin.register Tafsir do
  menu parent: "Content"
  actions :all, except: :destroy
  ActiveAdminViewHelpers.versionate(self)

  filter :verse_id
  filter :language

  index do
    id_column

    column :language do |resource|
      link_to resource.language_name, admin_language_path(resource.language_id)
    end

    column :verse do |resource|
      link_to resource.verse_id, admin_verse_path(resource.verse_id)
    end

    column :name do |resource|
      link_to resource.resource_content.name, [:admin, resource.resource_content]
    end
  end
end
