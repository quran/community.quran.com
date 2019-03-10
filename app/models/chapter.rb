class Chapter < QuranApiRecord
  has_many :verses, inverse_of: :chapter
  has_many :translated_names, as: :resource
  has_many :chapter_infos
  has_many :slugs

  serialize :pages

  alias_method :name, :id

  has_paper_trail on: :update, ignore: [:created_at, :updated_at]

  def add_slug(slug, locale=nil)
    require 'babosa'

    slugs.where(locale: locale, slug: slug.to_slug.normalize.transliterate.to_s).first_or_create
  end
end
