class Transliteration < QuranApiRecord
  has_paper_trail on: :update, ignore: [:created_at, :updated_at]
  include Resourceable

  belongs_to :resource, polymorphic: true
  belongs_to :language
end
