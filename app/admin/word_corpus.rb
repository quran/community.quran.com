ActiveAdmin.register WordCorpus do
  menu parent: "Research Data"
  actions :all, except: :destroy

  filter :location
end