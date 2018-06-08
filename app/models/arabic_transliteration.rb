class ArabicTransliteration < QuranApiRecord
  belongs_to :word, optional: true
  belongs_to :verse
  has_many :proof_read_comments, as: :resource
  has_paper_trail on: [:update, :destroy, :create], ignore: [:created_at, :updated_at]

  delegate :text_simple, :location, to: :word
  
  def name
    text
  end
end
