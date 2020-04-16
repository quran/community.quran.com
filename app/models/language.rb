class Language < QuranApiRecord
  serialize :es_indexes, Array

  has_many :translated_names, as: :resource
end
