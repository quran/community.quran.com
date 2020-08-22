ActiveAdmin.register Reciter do
  menu parent: "Settings"
  actions :all, except: :destroy

  ActiveAdminViewHelpers.render_translated_name_sidebar(self)
end
