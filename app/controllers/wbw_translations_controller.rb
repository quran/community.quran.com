class WbwTranslationsController < CommunityController
  attr_reader :language
  DEFAULT_LANGUAGE = 174 # Urdu

  before_action :detect_language
  before_action :check_permission, only: [:new, :edit, :update, :create]

  def index
    verses = Verse
    if params[:filter_juz].to_i > 0
      verses = verses.where(juz_number: params[:filter_juz].to_i)
    end

    if params[:filter_chapter].to_i > 0
      verses = verses.where(chapter_id: params[:filter_chapter].to_i)
    end

    if params[:filter_verse].to_i > 0
      verses = verses.where(verse_number: params[:filter_verse].to_i)
    end

    order = if params[:sort_order] && params[:sort_order] == 'desc'
              'desc'
            else
              'asc'
            end

    @verses = verses.order("verse_index #{order}").page(params[:page]).per(20)
  end

  def show
    @verse = Verse
               .includes(:translations, :words)
               .where(translations: { resource_content_id: eager_load_translations })
               .find(params[:id])
  end

  def new
    @verse = Verse
               .includes(:chapter, :translations)
               .where(translations: { resource_content_id: eager_load_translations })
               .find(params[:ayah])

    @wbw_translations = []

    @verse.words.order('position asc').each_with_index do |word, i|
      next if word.char_type_name == 'end'
      wbw_translation = @verse
                          .wbw_translations
                          .where(language_id: language.id)
                          .find_or_initialize_by(word_id: word.id)

      @wbw_translations << wbw_translation
    end
  end

  def create
    @verse = Verse.find(params[:verse_id])
    @verse.update(wbw_translations_params)

    redirect_to wbw_translation_path(@verse, language: language.id)
  end

  protected

  def wbw_translations_params
    params.require(:verse).permit wbw_translations_attributes: [
      :id,
      :word_id,
      :language_id,
      :text,
      :user_id,
    ]
  end

  def eager_load_translations
    if 174 == language.id
      # Urdu
      [54, 97]
    elsif 185 == language.id
      # Chinese
      [109, 56]
    elsif 175 == language.id
      # Uzbek
      [55, 127, 101]
    else
      []
    end
  end

  def check_permission
    resource = ResourceContent.translations.one_word.where(language: language).first

    unless resource.present? && can_manage?(resource)
      redirect_to wbw_translations_path(language: @language.id), alert: "Sorry you don't have access to this resource"
    end
  end

  protected

  def detect_language
    lang_from_params = (params[:language].presence || DEFAULT_LANGUAGE).to_i
    @language = Language.find_by_id(lang_from_params) || Language.find(DEFAULT_LANGUAGE)
    params[:language] = @language.id
  end
end