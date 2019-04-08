class WbwTranslationsController < CommunityController
  def index
    verses = Verse
=begin
    case params[:filter_progress]
             when 'completed'
               Verse.verse_with_full_arabic_transliterations
             when 'missing'
               Verse.verses_with_no_arabic_translitration
             when 'all'
               Verse.verse_with_words_and_arabic_transliterations
             else
               Verse.verses_with_missing_arabic_translitration
             end
=end
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


    madani_text = @verse.text_madani.strip.split(/\s+/)
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
        wbw_translation.text_madani ||= word.text_imlaei
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
    params[:language_id] = (params[:language_id].presence || 174).to_i
    @language = Language.find(params[:language_id])

    if params[:language_id] == 174
      [54, 97]
    else
      # Chinese 109, 56
      [109, 56]
    end
  end
end