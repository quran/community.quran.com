class QuranTableDetail < ApplicationRecord
  def self.refresh_tables_meta
    (Verse.connection.tables - ['refresh_tables_meta']).each do |name|
      table = QuranTableDetail.where(name: name).first_or_create

      result = Verse.connection.execute "select count(*) from #{name}"
      table.update(enteries: result.first['count'])
    end
  end

  def readonly?
    false
  end

  def load_table(page, limit)
    result = Verse.connection.execute "select * from #{name} offset #{page*limit} limit #{limit}"
  end
end