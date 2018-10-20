ActiveAdmin.register AudioFile do
  menu parent: "Media", priority: 1
  actions :all, except: :destroy

  index do
    id_column
    column :resource_type
    column :duration
    column :url
    column :format
    actions
  end

  permit_params do
    [
      :resource_type,
      :resource_id, :url,
      :duration,
      :segments,
      :recitation_id
    ]
  end
end
