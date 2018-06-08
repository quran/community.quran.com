class ArabicTransliterationsController < ApplicationController
  def show
    @verse = Verse.includes(words: :arabic_transliteration).find(params[:id])

    saved_page      = @verse.arabic_transliterations.detect(&:page_number)
    @predicted_page = saved_page&.page_number || (@verse.page_number * 1.6666).to_i

    to_javascript page_number: @predicted_page,
                  page_zoom:   saved_page&.zoom,
                  page_pos_x:  saved_page&.position_x,
                  page_pos_y:  saved_page&.position_y
  end
  
  def new
    @verse = Verse.includes(:chapter).find(params[:ayah])
    
    indopak          = @verse.text_indopak.strip.split(/\s+/)
    pause_mark_count = 0
    @arabic_transliterations = []
    saved_page      = @verse.arabic_transliterations.detect(&:page_number)
    @predicted_page = saved_page&.page_number || (@verse.page_number * 1.6666).to_i

    @verse.words.order('position asc').each_with_index do |word, i|
      next if word.char_type_name == 'end'
      transliteration = @verse.arabic_transliterations.find_or_initialize_by(word_id: word.id)
      
      if word.char_type_name == 'word'
        transliteration.indopak_text ||= indopak[i-pause_mark_count]
      else
        pause_mark_count += 1
      end
      
      transliteration.page_number ||= @predicted_page

      @arabic_transliterations << transliteration
    end
    
    to_javascript page_number: @predicted_page,
                  page_zoom:   saved_page&.zoom,
                  page_pos_x:  saved_page&.position_x,
                  page_pos_y:  saved_page&.position_y
  end
  
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
  
  def create
    verse = Verse.find(params[:verse_id])

    verse.attributes = arabic_transliterations_params
    verse.save validate: false
    redirect_to arabic_transliteration_path(verse), notice: "Saved successfully"
  end
  
  protected
  def arabic_transliterations_params
    params.require(:verse).permit arabic_transliterations_attributes: [
                                                                        :id,
                                                                        :indopak_text,
                                                                        :text,
                                                                        :word_id,
                                                                        :page_number,
                                                                        :position_x,
                                                                        :position_y,
                                                                        :zoom
                                                                      ]
  end

end
