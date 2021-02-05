class Word < QuranApiRecord
  has_paper_trail on: [:update, :destroy], ignore: [:created_at, :updated_at]

  belongs_to :verse
  belongs_to :char_type
  belongs_to :topic, optional: true
  belongs_to :token, optional: true

  has_many :word_translations
  has_many :transliterations, as: :resource
  has_many :word_synonyms
  has_many :synonyms, through: :word_synonyms

  has_one :word_lemma
  has_one :lemma, through: :word_lemma
  has_one :word_stem
  has_one :stem, through: :word_stem
  has_one :word_root
  has_one :root, through: :word_root
  has_one :pause_mark
  has_one :audio_file, as: :resource

  has_one :ur_wbw_translation, -> { where language_id: 174 }, class_name: 'WbwTranslation'
  has_one :zh_wbw_translation, -> { where language_id: 185 }, class_name: 'WbwTranslation'
  # Ubzek
  has_one :uz_wbw_translation, -> { where language_id: 175 }, class_name: 'WbwTranslation'
  has_one :ur_transliteration, -> { where language_name: 'urdu' }, class_name: 'Transliteration', as: :resource

  # Used for export translation
  ['en', 'id', 'bn', 'ur'].each do |lang|
    has_one "#{lang}_translation".to_sym, -> { where(language: Language.find_by_iso_code(lang)) }, class_name: 'WordTranslation'
  end

  has_one :word_corpus
  has_one :arabic_transliteration

  scope :words, -> { where char_type_id: 1 }
  default_scope { order 'position asc' }

  def v1_hex_to_char
    "&#x#{code_hex};"
  end

  def v2_hex_to_char
    code_v2.presence # || "&#x#{code_hex_v2};"
  end

  def humanize
    "#{location} - #{text_uthmani}"
  end

  def word?
    'word' == char_type_name
  end

  def pause_mark?
    'pause' == char_type_name
  end

  def sajdah?
    'sajdah' == char_type_name
  end

  def ayah_mark?
    'end' == char_type_name
  end

  def hizb?
    'rub-el-hizb' == char_type_name
  end
end