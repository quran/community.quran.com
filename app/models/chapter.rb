class Chapter < QuranApiRecord
  has_many :verses, inverse_of: :chapter
  has_many :translated_names, as: :resource
  has_many :chapter_infos
  has_many :slugs

  serialize :pages

  alias_method :name, :id

  has_paper_trail on: :update, ignore: [:created_at, :updated_at]

  def add_slug(slug, locale = 'en', is_default = false)
    require 'babosa'

    slug = slugs.where(slug: slug.to_slug.normalize.transliterate.to_s).first_or_initialize

    if slug.locale.blank?
      slug.locale = locale
    end

    slug.is_default = is_default
    slug.save

    slug
  end

  def humanize
    "#{chapter_number} - #{name_simple}"
  end
end
