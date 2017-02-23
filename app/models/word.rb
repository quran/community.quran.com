class Word < QuranApiRecord
  belongs_to :verse
  belongs_to :char_type
  has_many :translations, as: :resource
  has_many :transliterations, as: :resource
  has_many :audio_files, as: :resource
  has_many :pause_marks

  def code
    "&#x#{code_hex};"
  end

  def code_v3
    "&#x#{code_hex_v3};"
  end

  def audio
    "//audio.recitequran.com/wbw/arabic/wisam_sharieff/#{audio_url}"
  end
end
