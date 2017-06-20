ActiveAdmin.register Topic do
  menu parent: "Research Data"
  actions :all, except: :destroy

  filter :name
end