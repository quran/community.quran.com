class Tafsir < QuranApiRecord
  has_paper_trail on: :update, ignore: [:created_at, :updated_at]
  include Resourceable

  belongs_to :verse
  belongs_to :language
  has_many :foot_notes, as: :resource
end
