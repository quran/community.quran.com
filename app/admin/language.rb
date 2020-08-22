ActiveAdmin.register Language do
  menu parent: "Settings", priority: 1
  actions :all, except: :destroy

  ActiveAdminViewHelpers.render_translated_name_sidebar(self)

  filter :name
  filter :iso_code
  filter :direction
  filter :native_name

  permit_params do
    [:name, :iso_code, :native_name, :direction, :es_analyzer_default]
  end
end
