ActiveAdmin.register WordTranslation do
  menu parent: "Content"
  actions :all, except: :destroy

  ActiveAdminViewHelpers.versionate(self)

  filter :language
  filter :word_id

  index do
    column :id do |resource|
      link_to(resource.id, [:admin, resource])
    end
    column :language do |resource|
      resource.language_name
    end
    column :word
    column :text
    actions
  end

  show do
    attributes_table do
      row :id
      row :word
      row :language
      row :text do |resource|
        div class: resource.language_name.to_s.downcase do
          resource.text
        end
      end
      row :resource_content
    end

    if params[:version].to_i > 0
      ActiveAdminViewHelpers.diff_panel(self, resource)
    end
  end

  def scoped_collection
    super.includes :language # prevents N+1 queries to your database
  end

  permit_params do
    [:language_id, :word_id, :text, :language_name, :resource_content_id]
  end

  form do |f|
    f.inputs "Word Translation Form" do
      f.input :text
      f.input :language
      f.input :word_id
      f.input :language_name
    end
    f.actions
  end
end
