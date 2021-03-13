ActiveAdmin.register Audio::Section do
  active_admin_import(validate: false, on_duplicate_key_update: true)

  menu parent: "QuranicAudio"
  permit_params :name

  actions :all, except: :destroy
  searchable_select_options(scope: Audio::Section,
                            text_attribute: :name,
                            filter: lambda do |term, scope|
                              scope.ransack(name_like: term).result
                            end)
  index do
    id_column
    column :name
    actions
  end
end