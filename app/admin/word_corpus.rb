ActiveAdmin.register WordCorpus do
  menu parent: "Data"
  actions :all, except: :destroy

  filter :location
end