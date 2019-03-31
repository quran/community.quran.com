class WbwTranslationsController < CommunityController
  def index
    verses = case params[:filter_progress]
             when 'completed'
               Verse.verse_with_full_arabic_transliterations
             when 'missing'
               Verse.verses_with_no_arabic_translitration
             when 'all'
               Verse.verse_with_words_and_arabic_transliterations
             else
               Verse.verses_with_missing_arabic_translitration
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
    @verse = Verse.includes(words: :wbw_translation).find(params[:id])
  end
end