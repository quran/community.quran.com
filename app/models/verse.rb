class Verse < QuranApiRecord
  has_paper_trail on: [:update, :destroy], ignore: [:created_at, :updated_at]

  belongs_to :chapter, inverse_of: :verses, counter_cache: true
  belongs_to :verse_root, optional: true
  belongs_to :verse_lemma, optional: true
  belongs_to :verse_stem, optional: true
  
  has_many :tafsirs
  has_many :words
  has_many :actual_words, -> { where char_type_id: true }, class_name: 'Word'
  has_many :media_contents, as: :resource
  has_many :translations
  has_many :transliterations, as: :resource
  has_many :audio_files
  has_many :recitations, through: :audio_files
  has_many :roots, through: :words
  has_many :arabic_transliterations
  has_many :wbw_translations
  has_many :wbw_texts

  has_one :ur_transliteration, -> { where resource_content_id: 130}, class_name: 'Translation', as: :resource

  accepts_nested_attributes_for :arabic_transliterations
  accepts_nested_attributes_for :wbw_translations
  accepts_nested_attributes_for :wbw_texts

  def self.verses_with_no_arabic_translitration
    Verse
      .select('verses.*, count(words.*) as missing_transliteration_count')
      .joins(:words)
      .joins("left OUTER JOIN arabic_transliterations on arabic_transliterations.word_id = words.id")
      .where('arabic_transliterations.text is null')
      .where('words.char_type_id = 1')
      .preload(:actual_words)
      .group('verses.id')
  end
  
  def self.verses_with_missing_arabic_translitration
    Verse
      .select('verses.*, count(words.*) as missing_transliteration_count')
      .joins(:words)
      .joins("left OUTER JOIN arabic_transliterations on arabic_transliterations.word_id = words.id")
      .where('arabic_transliterations.id is null')
      .where('words.char_type_id = 1')
      .preload(:actual_words)
      .group('verses.id')
  end
  
  def self.verse_with_words_and_arabic_transliterations
    Verse
      .select('verses.*, count(words.*) as total_words, count(arabic_transliterations.*) as total_transliterations')
      .joins(:words)
      .joins("left OUTER JOIN arabic_transliterations on arabic_transliterations.word_id = words.id")
      .where('words.char_type_id = 1')
      .group('verses.id')
  end
  
  def self.verse_with_full_arabic_transliterations
    verse_with_words_and_arabic_transliterations
      .having('count(arabic_transliterations.*) = count(words.*)')
  end
  
  def arabic_transliteration_progress
    total_words   = self['total_words'] || actual_words.size
    missing_count = if self['missing_transliteration_count']
                      self['missing_transliteration_count']
                    elsif self['total_transliterations']
                      (total_words - self['total_transliterations'].to_i)
                    else
                      total_words - arabic_transliterations.size
                    end
    
    (100 - (missing_count / total_words.to_f)*100).to_i.abs
  end

  def wbw_translation_progress(language_id)
    total_words = words.words.count
    words_with_translations = WbwTranslation.where(verse_id: id, language_id: language_id).count
    missing_count = [total_words - words_with_translations, 0].max

    (100 - (missing_count / total_words.to_f)*100).to_i.abs
  end
end
