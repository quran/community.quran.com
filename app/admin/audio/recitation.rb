ActiveAdmin.register Audio::Recitation do
  active_admin_import(validate: false, on_duplicate_key_update: true)

  menu parent: "QuranicAudio"
  actions :all, except: :destroy
  searchable_select_options(scope: Audio::Recitation,
                            text_attribute: :name,
                            filter: lambda do |term, scope|
                              scope.ransack(name_like: term).result
                            end)

  ActiveAdminViewHelpers.render_translated_name_sidebar(self)

  filter :name
  filter :home
  filter :torrent_leechers
  filter :torrent_seeders
  filter :section, as: :searchable_select,
         ajax: {resource: Audio::Section}

  index do
    id_column
    column :name
    column :relative_path
    column :section
    column :home
    column :torrent_leechers
    column :torrent_seeders

    actions
  end

  def scoped_collection
    super.includes :section
  end

  sidebar 'Chang Log', only: :show do
    table do
      thead do
        td :id
        td :des
      end

      tbody do
        resource.audio_change_logs.each do |log|
          tr do
            td link_to(log.id, [:admin, log])
            td log.mini_desc
          end
        end
      end
    end
  end

  sidebar "Related Recitation", only: :show do
    table do
      thead do
        td :id
        td :name
      end

      tbody do
        resource.related_recitations.each do |recitation|
          tr do
            related = recitation.related_audio_recitation
            td link_to(related.id, [:admin, related])
            td related.name
          end
        end
      end
    end
  end
end