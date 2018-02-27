class ArabicTransliterationsController < ApplicationController
  def index
    @verses_without_transliteration = Verse.verses_without_arabic_translitration.page(params[:page]).per(10)
  end
end
