ActiveAdmin.register WordLemma do
  menu parent: "Data"
  actions :all, except: :destroy

  filter :word_id
end