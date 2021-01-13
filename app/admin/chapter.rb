ActiveAdmin.register Chapter do
 searchable_select_options(scope: Chapter.all,
                          text_attribute: :humanize,
                          filter: lambda do |term, scope|
                              scope.ransack(chapter_number_eq: term, name_like: term).result
end)


  menu parent: "Quran", priority: 1
  actions :all, except: [:destroy, :new]

  permit_params do
    [:name_simple, :name_arabic, :name_complex, :bismillah_pre, :revelation_order]
  end

  ActiveAdminViewHelpers.render_translated_name_sidebar(self)
  ActiveAdminViewHelpers.render_slugs(self)

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
