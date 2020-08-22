ActiveAdmin.register VerseLemma do
  menu parent: "Data"
  actions :all, except: :destroy

  filter :text_madani
  filter :text_clean
end