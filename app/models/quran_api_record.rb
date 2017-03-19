class QuranApiRecord < ActiveRecord::Base
  self.abstract_class = true
  self.establish_connection(:quran_api_db)

  #has_paper_trail on: [:update, :destroy], ignore: [:created_at, :updated_at]
end