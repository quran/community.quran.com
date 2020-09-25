class AudioFile < QuranApiRecord
  belongs_to :verse
  belongs_to :recitation

  serialize :segments
end
