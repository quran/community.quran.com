ActiveAdmin.register FootNote do
  menu parent: "Content"
  actions :all, except: :destroy
  ActiveAdminViewHelpers.versionate(self)

  filter :language
  filter :translation_id

  show do
      attributes_table do
      row :id
      row :translation
      row :language
      row :resource_content
      row :text
    end
  
    if params[:version]
      ActiveAdminViewHelpers.diff_panel(self, resource)
    end
    row :created_at
    row :updated_at
  end

  form do |f|
    f.inputs "Footnote Details" do
      f.input :text
      f.input :language
      f.input :language_name
      f.input :translation_id
      f.input :resource_content
    end
    f.actions
  end
  
# See permitted parameters documentation:
# https://github.com/activeadmin/activeadmin/blob/master/docs/2-resource-customization.md#setting-up-strong-parameters
#
# permit_params :list, :of, :attributes, :on, :model
#
# or
#
 permit_params do
  [:language_id, :resource_content_id, :text, :translation_id, :language_name]
 end
end