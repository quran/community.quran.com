ActiveAdmin.register AudioFile do
  menu parent: "Media", priority: 1
  actions :all, except: :destroy

  index do
    id_column
    column :verse do |obj|
      link_to obj.verse_id, admin_verse_path(obj.verse_id)
    end
    column :duration
    column :url
    column :format
    actions
  end

  permit_params do
    [
      :verse_id,
      :url,
      :duration,
      :segments,
      :recitation_id
    ]
  end
end
