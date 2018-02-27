class Verse < QuranApiRecord
  belongs_to :chapter, inverse_of: :verses, counter_cache: true
  belongs_to :verse_root
  belongs_to :verse_lemma
  belongs_to :verse_stem
  
  has_many :tafsirs
  has_many :words
  has_many :media_contents, as: :resource
  has_many :translations, as: :resource
  has_many :transliterations, as: :resource
  has_many :audio_files, as: :resource
  has_many :recitations, through: :audio_files
  has_many :roots, through: :words
  
  has_paper_trail on: [:update, :destroy, :create], ignore: [:created_at, :updated_at]
  
  def self.verses_without_arabic_translitration
=begin
    # Lets not push this data into transliterations for now
    Verse
      .select('verses.*, count(words.*) as missing_translitration_words_count')
      .joins(:words)
      .joins("left OUTER JOIN transliterations on transliterations.resource_type = 'Word' and
               transliterations.resource_id = words.id and transliterations.language_name = 'urdu'"
      )
      .where('transliterations.id is null')
      .where('words.char_type_id = 1')
      .group('verses.id')
      .order('verse_index asc')
=end
    
    Verse
      .select('verses.*, count(words.*) as missing_translitration_words_count')
      .joins(:words)
      .joins("left OUTER JOIN arabic_transliterations on arabic_transliterations.word_id = words.id")
      .where('arabic_transliterations.id is null')
      .where('words.char_type_id = 1')
      .group('verses.id')
      .order('verse_index asc')
  end
  
  def self.verse_with_words_count
    Verse
      .select('verses.*, count(words.*) as words_count')
      .joins(:words)
      .group('verses.id')
      .where('words.char_type_id = 1')
      .order('verse_index asc')
  end
  
  def arabic_transliteration_progress
    (100 - (missing_translitration_words_count / words.where(char_type_id: 1).size.to_f)*100).to_i
  end
end
