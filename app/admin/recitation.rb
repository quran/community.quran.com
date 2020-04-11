ActiveAdmin.register Recitation do
  menu parent: "Settings", priority: 1
  actions :all, except: :destroy

  filter :reciter
  filter :recitation_style

  scope :approved, default: true, group: :enabled
  scope :un_approved, group: :enabled

  permit_params do
    [:reciter_id, :recitation_style_id, :resource_content_id]
  end

  show do
    attributes_table do
      row :id
      row :reciter
      row :reciter_name
      row :resource_content do |r|
        if r.resource_content
          link_to "#{r.resource_content.id}-#{r.resource_content.name}", [:admin, r.resource_content]
        end
      end
      row :recitation_style do |r|
        link_to r.style, [:admin, r.recitation_style]
      end
      row :approved do |r|
        r.approved?
      end
    end
  end

  sidebar "Audio files", only: :show do
    div do
      link_to "View audio files", "/admin/audio_files?utf8=✓&q%5Brecitation_id_eq%5D=#{resource.id}"
    end
  end
end
