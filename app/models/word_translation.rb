class WordTranslation < QuranApiRecord
  has_paper_trail on: :update, ignore: [:created_at, :updated_at]
  include Resourceable

  belongs_to :word
  belongs_to :language
end
