ActiveAdmin.register Chapter do
  menu parent: "Quran", priority: 1
  actions :all, except: [:destroy, :new]
  ActiveAdminViewHelpers.render_translated_name_sidebar(self)

  filter :chapter_number
  filter :bismillah_pre
  filter :revelation_order
  filter :revelation_place
  filter :name_complex

  index do
    column :chapter_number do |chapter| link_to chapter.id,  admin_chapter_path(chapter) end
    column :bismillah_pre
    column :revelation_order
    column :revelation_place
    column :name_complex
    column :name_arabic
    column :pages
    column :verses_count
  end
end
