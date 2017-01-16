class Word < QuranApiRecord
  belongs_to :verse
  belongs_to :char_type
  has_many :translations, as: :resource
  has_many :transliterations, as: :resource
  has_many :audio_files, as: :resource

  def code
    "&#x#{code_hex};"
  end
end
