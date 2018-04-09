ActiveAdmin.register RecitationStyle do
  menu parent: "Settings", priority: 4
  actions :all, except: :destroy
end
