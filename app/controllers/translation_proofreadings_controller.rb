class TranslationProofreadingsController < CommunityController
  before_action :find_resource

  def show
    @translation = Translation
                       .includes(:verse, :foot_notes)
                       .where(resource_content_id: @resource.id)
                       .find_by_verse_id(params[:id])
  end

  def edit
    @translation = Translation
                       .includes(:verse, :foot_notes)
                       .where(resource_content_id: @resource.id)
                       .find_by_verse_id(params[:id])
  end

  def update
    @translation = Translation
                       .where(resource_content_id: @resource.id)
                       .find_by_verse_id(params[:id])

    if @translation.update(translation_params)
      redirect_to translation_proofreading_path(@translation.verse.id, resource_id: @resource.id), notice: "updated successfully"
    else
      render action: :edit, alert: @translation.errors.full_messages
    end
  end

  def index
    translations = Translation.includes(:verse, :foot_notes).where(resource_content_id: @resource.id)

    if params[:filter_chapter].to_i > 0
      translations = translations.where("verses.chapter_id": params[:filter_chapter].to_i)
    end

    if params[:filter_verse].to_i > 0
      translations = translations.where("verses.verse_number": params[:filter_verse].to_i)
    end

    order = if params[:sort_order] && params[:sort_order] == 'desc'
              'desc'
            else
              'asc'
            end

    @translations = translations.order("verses.verse_index #{order}").page(params[:page]).per(20)
  end

  def create
    verse = Verse.find(params[:verse_id])

    verse.attributes = arabic_transliterations_params
    verse.save validate: false
    redirect_to arabic_transliteration_path(verse), notice: "Saved successfully"
  end

  protected

  def translation_params
    params.require(:translation).permit(
        :text,
        foot_notes_attributes: [
            :id,
            :text
        ]
    )
  end

  def find_resource
    @resource = ResourceContent.find(params[:resource_id])
  end

end
