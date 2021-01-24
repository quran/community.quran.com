class WbwTranslationsController < CommunityController
  before_action :check_permission, only: [:new, :edit, :update, :create]

  def index
    verses = Verse
    params[:language_id] ||= (params[:language_id].presence || 174).to_i
    @language = Language.find(params[:language_id].presence || 174)

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
                 .where(translations: {resource_content_id: eager_load_translations})
                 .find(params[:id])
  end

  def new
    @verse = Verse
                 .includes(:chapter, :translations)
                 .where(translations: {resource_content_id: eager_load_translations})
                 .find(params[:ayah])


    madani_text = @verse.text_uthmani.strip.split(/\s+/)
    pause_mark_count = 0
    @wbw_translations = []

    @verse.words.order('position asc').each_with_index do |word, i|
      next if word.char_type_name == 'end'
      wbw_translation = @verse
                            .wbw_translations
                            .where(language_id: params[:language_id])
                            .find_or_initialize_by(word_id: word.id)

      wbw_translation.text_indopak ||= word.text_indopak

      if word.char_type_name == 'word'
        wbw_translation.text_madani ||= madani_text[i - pause_mark_count]
      else
        wbw_translation.text_madani ||= word.text_uthmani
        pause_mark_count += 1
      end

      @wbw_translations << wbw_translation
    end
  end

  def create
    @verse = Verse.find(params[:verse_id])
    @verse.update_attributes wbw_translations_params

    redirect_to wbw_translation_path(@verse, language_id: params[:language_id])
  end

  protected

  def wbw_translations_params
    params.require(:verse).permit wbw_translations_attributes: [
        :word_id,
        :language_id,
        :text_madani,
        :text_indopak,
        :text,
        :user_id,
        :id
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
      # 55 Muhammad Sodiq Muhammad Yusuf (Latin) which we're updating to new dialect
      # 127
      [55, 127, 101]
    else
      []
    end
  end

  def check_permission
    resource = ResourceContent.translations.one_word.where(language: language).first

    unless resource.present? && can_manage?(resource)
      redirect_to wbw_translations_path(language_id: @language.id), alert: "Sorry you don't have access to this resource"
    end
  end

  def language
    if @language
      @language
    else
      params[:language_id] = (params[:language_id].presence || 174).to_i
      @language = Language.find(params[:language_id])
    end
  end
end