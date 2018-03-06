class ArabicTransliteration < QuranApiRecord
  belongs_to :word
  belongs_to :verse

  has_paper_trail on: [:update, :destroy, :create], ignore: [:created_at, :updated_at]

  delegate :text_simple, :location, to: :word
end
