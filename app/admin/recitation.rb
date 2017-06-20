ActiveAdmin.register Recitation do
  menu parent: "Settings", priority: 1
  actions :all, except: :destroy

  filter :reciter
  filter :recitation_style

  permit_params do
    [:reciter_id, :recitation_style_id, :resource_content_id]
  end

  sidebar "Audio files", only: :show do
    div do
      link_to "View audio files", "/admin/audio_files?utf8=✓&q%5Brecitation_id_eq%5D=#{resource.id}"
    end
  end
end
