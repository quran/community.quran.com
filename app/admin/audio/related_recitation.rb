ActiveAdmin.register Audio::RelatedRecitation do
  menu parent: "QuranicAudio"
  actions :all, except: :destroy

  filter :audio_recitation, as: :searchable_select,
         ajax: {resource: Audio::Recitation}

  filter :related_audio_recitation, as: :searchable_select,
         ajax: {resource: Audio::Recitation}


  index do
    id_column
    column :audio_recitation
    column :related_audio_recitation

    actions
  end

  def scoped_collection
    super.includes :audio_recitation, :related_audio_recitation
  end
end