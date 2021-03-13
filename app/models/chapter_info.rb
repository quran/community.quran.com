class ChapterInfo < QuranApiRecord
  has_paper_trail on: :update, ignore: [:created_at, :updated_at]
  include Resourceable

  belongs_to :chapter
  belongs_to :language
end
