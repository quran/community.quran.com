ActiveAdmin.register MuhsafPage do
  menu parent: "Quran", priority: 6
  actions :all, except: [:destroy, :new]
end
