class SurahInfosController < CommunityController
  before_action :load_access
  before_action :check_permission, only: [:new, :edit, :update, :create]

  def index
    @surah_infos = ChapterInfo.order("chapter_id ASC").where(language: language)
  end

  def show
    @info = ChapterInfo.where(language: language, chapter_id: params[:id]).first
  end

  def edit
    @info = ChapterInfo.where(language: language, chapter_id: params[:id]).first
  end

  def update
    @info = ChapterInfo.where(language: language, chapter_id: params[:id]).first

    if @info.update(info_params)
      redirect_to surah_info_path(@info.chapter_id, resource: @resource.id, language_id: @info.language_id), notice: "Info updated successfully."
    else
      render action: :edit
    end
  end

  protected

  def info_params
    params.require(:chapter_info).permit(:short_text, :text)
  end

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

  def check_permission
    if @resource.blank? || @access.blank?
      redirect_to surah_infos_path(language_id: @language.id), alert: "Sorry you don't have access to this resource"
    end
  end

  def load_access
    @resource = ResourceContent.chapter_info.where(language: language).first
    @access = can_manage?(@resource)
  end

  def language
    if @language
      @language
    else
      # default will be English
      params[:language_id] = (params[:language_id].presence || 38).to_i
      @language = Language.find(params[:language_id])
    end
  end
end