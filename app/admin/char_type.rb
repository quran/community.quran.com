ActiveAdmin.register CharType do
  menu parent: "Settings", priority: 10
  actions :all, except: :destroy

  permit_params do
    [:name, :parent_id, :description]
  end
end
