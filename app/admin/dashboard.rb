ActiveAdmin.register_page "Dashboard" do
  
  menu priority: 1, label: proc { I18n.t("active_admin.dashboard") }
  
  content title: proc { I18n.t("active_admin.dashboard") } do
    div class: "blank_slate_container", id: "dashboard_default_message" do
      panel "Recent changes" do
        table_for PaperTrail::Version.order('id desc').limit(20) do # Use PaperTrail::Version if this throws an error
          column ("Item") { |v| link_to v.item_type.underscore.humanize, [:admin, v.item, version: v.id] }
          column ("Modified at") { |v| v.created_at.to_s :long }
          column ("Admin") { |v| link_to AdminUser.find(v.whodunnit).email, [:admin, AdminUser.find(v.whodunnit)] }
        end
      end
    end
    
    columns do
      column do
        panel "Export Translation as SQLite DB" do
          form_tag export_sqlite_admin_resource_contents_path, method: 'put' do |form|
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
    
    # Here is an example of a simple dashboard with columns and panels.
    #
    # columns do
    #   column do
    #     panel "Recent Posts" do
    #       ul do
    #         Post.recent(5).map do |post|
    #           li link_to(post.title, admin_post_path(post))
    #         end
    #       end
    #     end
    #   end
    
    #   column do
    #     panel "Info" do
    #       para "Welcome to ActiveAdmin."
    #     end
    #   end
    # end
  end # content
end
