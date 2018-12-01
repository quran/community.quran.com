class Chapter < QuranApiRecord
  has_many :verses, inverse_of: :chapter
  has_many :translated_names, as: :resource
  has_many :chapter_infos

  serialize :pages

  alias_method :name, :id

  has_paper_trail on: :update, ignore: [:created_at, :updated_at]
end
