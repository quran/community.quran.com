
class Juz < QuranApiRecord
  has_many :verses, foreign_key: :juz_number
  has_many :chapters, through: :verses
  
  serialize :verse_mapping, Hash
end
