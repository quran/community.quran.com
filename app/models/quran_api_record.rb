class QuranApiRecord < ActiveRecord::Base
  self.abstract_class = true
  self.establish_connection(:quran_api_db)
end