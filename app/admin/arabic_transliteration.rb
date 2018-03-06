ActiveAdmin.register ArabicTransliteration do
  menu parent: "Research Data", priority: 1
  actions :all, except: :destroy

  ActiveAdminViewHelpers.versionate(self)

  index do
    id_column
    column :verse_id
    column :word_id
    column :text
    column :indopak_text
    actions
  end
  
  form do |f|
    render 'shared/keyboard_assets'
    f.inputs "ArabicTransliteration detail" do
      f.input :verse_id
      f.input :word_id
      f.input :text, as: :text, field_html: { class: 'transliteration' }
      f.input :indopak_text, as: :text
    end
    f.actions
  end
  
  permit_params do
    [:resource_type, :resource_id, :url, :duration, :segments, :recitation_id]
  end
end
