class Tafsir < QuranApiRecord
  has_paper_trail on: :update, ignore: [:created_at, :updated_at]

  belongs_to :verse
  belongs_to :language
  belongs_to :resource_content
  has_many :foot_notes, as: :resource
end
