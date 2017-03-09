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
end
