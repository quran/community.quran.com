class ArabicTransliteration < QuranApiRecord
  belongs_to :word
  belongs_to :verse
  
  delegate :text_simple, :location, to: :word
end
