class FootNote < QuranApiRecord
  has_paper_trail on: :update, ignore: [:created_at, :updated_at]
  
  belongs_to :translation
  belongs_to :language
  belongs_to :resource_content
end
