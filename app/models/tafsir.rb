class Tafsir < QuranApiRecord
  belongs_to :verse
  belongs_to :language
  belongs_to :resource_content
  has_many :foot_notes, as: :resource

  has_paper_trail on: [:update, :destroy, :create], ignore: [:created_at, :updated_at]
end
