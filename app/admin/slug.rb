ActiveAdmin.register Slug do
  menu parent: "Content"
  actions :all

  filter :locale
  filter :chapter

  show do
    attributes_table do
      row :id
      row :chapter
      row :slug
      row :locale
    end
  end

# See permitted parameters documentation:
# https://github.com/activeadmin/activeadmin/blob/master/docs/2-resource-customization.md#setting-up-strong-parameters
#
# permit_params :list, :of, :attributes, :on, :model
#
# or
#
  permit_params do
    [:locale, :chapter_id, :slug]
  end

  controller do
    def create
      p = permitted_params[:slug]
      chapter = Chapter.find(p[:chapter_id])

      chapter.add_slug(p[:slug], p[:locale])

      redirect_to [:admin, chapter], notice: 'Slug created'
    end
  end
end
