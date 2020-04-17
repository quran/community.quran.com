ActiveAdmin.register Topic do
  menu parent: "Data"
  actions :all, except: :destroy

  filter :name
end