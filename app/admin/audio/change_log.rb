ActiveAdmin.register Audio::ChangeLog do
  menu parent: "QuranicAudio"
  actions :all, except: :destroy

  filter :audio_recitation, as: :searchable_select,
         ajax: {resource: Audio::Recitation}
  filter :date

  index do
    id_column
    column :audio_recitation
    column :date
    column :mini_desc

    actions
  end

  def scoped_collection
    super.includes :audio_recitation
  end
end