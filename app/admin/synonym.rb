ActiveAdmin.register Synonym do
  permit_params :text, :synonyms

  filter :text
  filter :where_synonyms_contains, label: :synonyms, as: :string

  show do
    attributes_table do
      row :id
      row :text
      row :synonyms
      row :created_at
      row :updated_at

      row :words do |resource|
        resource.words.select(:text_uthmani_simple).group(:text_uthmani_simple, :position).size.each do |k, v|
          span do
            link_to "(#{v}) - #{k}", "/admin/words?utf8=%E2%9C%93&q%5Btext_simple_equals%5D=#{k}"
          end
        end

        nil
      end
    end
  end
end
