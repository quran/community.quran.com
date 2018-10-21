ActiveAdmin.register_page "Dashboard" do
  
  menu priority: 1, label: proc { I18n.t("active_admin.dashboard") }
  
  content title: proc { I18n.t("active_admin.dashboard") } do
    div class: "blank_slate_container", id: "dashboard_default_message" do
      panel "Recent changes (Total #{PaperTrail::Version.count}) #{link_to 'View all changes', '/admin/content_changes'}".html_safe do
        table_for PaperTrail::Version.order('id desc').limit(20) do # Use PaperTrail::Version if this throws an error
          column ("ID") { |v| link_to v.id, "/admin/content_changes/#{v.id}" }
          column ("Item") { |v| v.item_type }
          column ("Event") { |v| v.event }
          column ("Modified at") { |v| v.created_at.to_s :long }
          column ("Admin") { |v| link_to(AdminUser.find(v.whodunnit).email, [:admin, AdminUser.find(v.whodunnit)]) if AdminUser.find_by_id(v.whodunnit) }
        end
      end
    end
    
    columns do
      column do
        panel "Export Translation as SQLite DB" do
          form_tag export_sqlite_admin_resource_content_path(1), method: 'put' do |form|
            translations = ResourceContent.translations.one_verse.approved
            label_tag(:translation, "Select translation") +
            select_tag(:translation, options_from_collection_for_select(translations, :id, :name)) +
            text_field_tag(:name, '', placeholder: 'Enter filename') +
            submit_tag("Export!", data: { disable_with: 'Please wait...' })
          end
        end
      end
      
      column do
        panel "Export Word as SQLite DB" do
          form_tag export_sqlite_admin_words_path, method: 'put' do |form|
            label_tag(:name, "Filename") +
            text_field_tag(:name, 'words', placeholder: 'Enter filename') +
            submit_tag("Export!", data: { disable_with: 'Please wait...' })
          end
        end
      end
    end
    
    columns do
      column do
        p ENV['REDIS_TOGO_URL']
      end
    end
  end
end
