ActiveAdmin.register WordLemma do
  menu parent: "Research Data"
  actions :all, except: :destroy

  filter :word_id
end