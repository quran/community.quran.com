ActiveAdmin.register Synonym do
  permit_params :text, :synonyms

  filter :text

  show do
    attributes_table do
      row :id
      row :text
      row :synonyms

      row :words do |resource|
        resource.words.group(:text_simple).size.each do |k, v|
          span do
            link_to "(#{v}) - #{k}", "/admin/words?utf8=%E2%9C%93&q%5Btext_simple_equals%5D=#{k}"
            #
            #
          end
        end

        false && resource.words.each do |word|

          span do
            link_to word.text_madani, [:admin, word], class: 'ml-2'


            # http://localhost:3000/admin/words?text_madani_equals=word.text_madani
          end
        end

        nil
      end
    end
  end
end
