ActiveAdmin.register RecitationStyle do
  menu parent: "Settings", priority: 4
  actions :all, except: :destroy

  searchable_select_options(scope: RecitationStyle,
                            text_attribute: :style,
                            filter: lambda do |term, scope|
                              scope.ransack(style_like: term).result
                            end)

end
