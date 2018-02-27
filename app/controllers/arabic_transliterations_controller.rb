class ArabicTransliterationsController < ApplicationController
  def new
     @verse = Verse.find(params[:ayah])
     @predicted_page = (@verse.page_number * 1.6666).to_i
     
     to_javascript page_number: @predicted_page
  end
  
  def index
    verses = case params[:filter_progress]
               when 'completed'
                 Verse.verse_with_full_arabic_transliterations
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
end
