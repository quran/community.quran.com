ActiveAdmin.register Author do
  menu parent: "Settings"
  actions :all, except: :destroy

  ActiveAdminViewHelpers.render_translated_name_sidebar(self)

  permit_params do
    [:name, :url]
  end
end
