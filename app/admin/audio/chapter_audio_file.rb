ActiveAdmin.register Audio::ChapterAudioFile do
  active_admin_import(validate: false, on_duplicate_key_update: true)

  menu parent: "QuranicAudio"
  actions :all, except: :destroy

  filter :audio_recitation, as: :searchable_select,
         ajax: {resource: Audio::Recitation}

  filter :chapter_id
  filter :format


  index do
    id_column
    column :chapter
    column :audio_recitation
    column :total_files
    column :bit_rate
    column :file_name
    column :format

    actions
  end

  sidebar 'Audio URL', only: :show do
    p link_to "View", resource.audio_url
  end

  def scoped_collection
    super.includes :chapter, :audio_recitation
  end
end