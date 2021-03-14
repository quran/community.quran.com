ActiveAdmin.register ResourceContent do
  searchable_select_options(scope: ResourceContent,
                            text_attribute: :name,
                            filter: lambda do |term, scope|
                              scope.ransack(id_eq: term, name_like: term).result
                            end
  )
  ActiveAdminViewHelpers.render_translated_name_sidebar(self)

  menu parent: "Content", priority: 10
  actions :all, except: :destroy

  filter :approved
  filter :name
  filter :cardinality_type, as: :select, collection: -> do
    ResourceContent.collection_for_cardinality_type
  end
  filter :resource_type, as: :select, collection: -> do
    ResourceContent.collection_for_resource_type
  end
  filter :sub_type, as: :select, collection: -> do
    ResourceContent.collection_for_sub_type
  end
  filter :language_id, as: :searchable_select,
         ajax: {resource: Language}

  action_item :show, only: :show do
    link_to approve_admin_resource_content_path(resource), method: :put, data: {confirm: "Are you sure?"} do
      resource.approved? ? "Un Approve!" : "Approve!"
    end
  end

  member_action :approve, method: 'put' do
    resource.toggle_approve!

    redirect_to [:admin, resource], notice: resource.approved? ? 'Approved successfully' : 'Un approved successfully'
  end

  member_action :export_sqlite, method: 'put' do
    resource = ResourceContent.find_by(id: params[:translation] || params[:id])
    #TODO: use sidekie
    file_path = ExportTranslationJob.new.perform(resource.id, params[:resource_content][:name])

    send_file file_path
  end

  index do
    id_column

    column :author do |resource|
      link_to resource.author_name, admin_author_path(resource.author_id) if resource.author_id
    end

    column :language do |resource|
      link_to resource.language_name, admin_language_path(resource.language_id) if resource.language_id
    end

    column :priority
    column :name
    column :approved
    column :cardinality_type
    column :sub_type
    actions
  end

  show do
    attributes_table do
      row :id
      row :name
      row :approved
      row :language
      row :priority
      row :cardinality_type
      row :sub_type
      row :resource_type
      row :slug
      row :author
      row :data_source
      row :mobile_translation_id
      row :sqlite_file_url
      row :created_at
      row :updated_at
      row :resource_info do
        div resource.resource_info.to_s.html_safe
      end
    end
    active_admin_comments
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

      toolbar = [
          ['bold', 'italic', 'underline', 'strike', 'size'],
          ['link', 'blockquote', 'code-block'],
          [{'script': 'sub'}, {'script': 'super'}],
          [{'align': []}, {list: 'ordered'}, {list: 'bullet'}],
          [{'color': []}, {'background': []}],
          [header: [], font: []],
          ['clean'],
      ]

      f.input :resource_info, as: :quill_editor, input_html: {
          data: {
              options:
                  {
                      modules: {
                          toolbar: toolbar
                      }
                  }
          }
      }

    end
    f.actions
  end

  permit_params do
    [
        :name,
        :author_name,
        :language_name,
        :approved,
        :language_id,
        :cardinality_type,
        :resource_type,
        :sub_type,
        :author_id,
        :data_source_id,
        :slug,
        :priority,
        :mobile_translation_id,
        :resource_info
    ]
  end

  def scoped_collection
    super.includes :language
  end

  sidebar "Data for this resource", only: :show do
    div do
      if resource.translation?
        link_to "Translations", "/admin/translations?utf8=%E2%9C%93&q%5Bresource_content_id_eq%5D=#{resource.id}"
      elsif resource.tafisr?
        link_to "Tafsir", "/admin/tafsirs?utf8=%E2%9C%93&q%5Bresource_content_id_eq%5D=#{resource.id}"
      elsif resource.transliteration?
        link_to "transliteration", "/admin/transliterations?utf8=%E2%9C%93&q%5Bresource_content_id_eq%5D=#{resource.id}"
      elsif resource.chapter_info?
        link_to "Chapter info", "/admin/chapter_infos?utf8=%E2%9C%93&q%5Bresource_content_id_eq%5D=#{resource.id}"
      elsif resource.video?
        link_to "Media content", "/admin/media_contents?utf8=%E2%9C%93&q%5Bresource_content_id_eq%5D=#{resource.id}"
      elsif resource.recitation?
        if resource.chapter?
          link_to "Surah recitations", "/admin/audio_chapter_audio_files?utf8=%E2%9C%93&q%5Bresource_content_id_eq%5D=#{resource.id}"
        else
          link_to "Ayah recitations", "/admin/recitations?utf8=%E2%9C%93&q%5Bresource_content_id_eq%5D=#{resource.id}"
        end
      elsif resource.foot_note?
        link_to "Footnotes", "/admin/foot_notes?utf8=%E2%9C%93&q%5Bresource_content_id_eq%5D=#{resource.id}"
      end
    end
  end

  sidebar "Export to sqlite db", only: :show, if: -> { resource.translation? || resource.tafisr? } do
    div do
      semantic_form_for resource, url: export_sqlite_admin_resource_content_path(resource), html: {method: 'put'} do |form|
        form.input(:name, label: false, hint: 'Enter file name', required: true) +
            form.submit("Export!!")
      end
    end
  end
end
