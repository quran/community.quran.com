ActiveAdmin.register QuranTableDetail do
  menu parent: "Data", priority: 1

  show do
    attributes_table do
      row :id
      row :name
      row :enteries
      row :updated_at
    end

    panel "Table Preview ( first 30 rows)" do
      enteries = resource.load_table(params[:page] || 0, 30)

      table do
        thead do
          enteries.fields.each do |c|
            td c
          end
        end

        tbody do
          enteries.each do |row|
            tr do
              row.keys.each do |c|
                td truncate(row[c].to_s, length: 150)
              end
            end
          end
          nil
        end
      end
    end
  end
end
