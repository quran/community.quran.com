ActiveAdmin.register Recitation do
  menu parent: "Settings", priority: 1
  actions :all, except: :destroy

  filter :reciter
  filter :recitation_style

  scope :approved, default: true, group: :enabled
  scope :un_approved, group: :enabled

  permit_params do
    [
        :reciter_id,
        :recitation_style_id,
        :resource_content_id
    ]
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

      row :resource_info do
        div resource.resource_info.to_s.html_safe
      end
    end
  end

  form do |f|
    f.inputs "Resource content Details" do
      f.input :name
      f.input :author_name
      f.input :slug
      f.input :approved
      f.input :language
      f.input :language_name
      f.input :priority
      f.input :mobile_translation_id

      f.input :cardinality_type, as: :select, collection: ResourceContent.collection_for_cardinality_type
      f.input :resource_type, as: :select, collection: ResourceContent.collection_for_resource_type
      f.input :sub_type, as: :select, collection: ResourceContent.collection_for_sub_type
      f.input :author
      f.input :data_source
      f.input :resource_info, as: :froala_editor

    end
    f.actions
  end

  sidebar "Audio files", only: :show do
    div do
      link_to "View audio files", "/admin/audio_files?utf8=✓&q%5Brecitation_id_eq%5D=#{resource.id}"
    end
  end
end
