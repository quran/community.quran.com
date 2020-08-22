ActiveAdmin.register Author do
  menu parent: "Settings"
  actions :all, except: :destroy

  ActiveAdminViewHelpers.render_translated_name_sidebar(self)

  permit_params do
    [:name, :url]
  end

  show do
    attributes_table do
      row :id
      row :name
      row :url
    end

    active_admin_comments
  end
end
