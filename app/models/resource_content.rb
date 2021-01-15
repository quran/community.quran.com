class ResourceContent < QuranApiRecord
  scope :translations, -> { where sub_type: [SubType::Translation, SubType::Transliteration] }
  scope :media, -> { where sub_type: SubType::Video }
  scope :tafsirs, -> { where sub_type: SubType::Tafsir }
  scope :chapter_info, -> { where sub_type: SubType::Info }
  scope :one_verse, -> { where cardinality_type: CardinalityType::OneVerse }
  scope :one_chapter, -> { where cardinality_type: CardinalityType::OneChapter }
  scope :one_word, -> { where cardinality_type: CardinalityType::OneWord }
  scope :recitations, -> { where sub_type: SubType::Audio}

  scope :approved, -> { where approved: true }
  
  belongs_to :author
  belongs_to :language
  belongs_to :data_source

  has_many :translated_names, as: :resource

  after_update :update_related_content

  module CardinalityType
    OneVerse = '1_ayah'
    OneWord = '1_word'
    NVerse = 'n_ayah'
    OneChapter = '1_chapter'
  end

  module ResourceType
    Audio = 'audio'
    Content = 'content'
    Quran = 'quran'
    Media = 'media'
  end

  module SubType
    Translation = 'translation'
    Tafsir = 'tafsir'
    Transliteration = 'transliteration'
    Font = 'font'
    Image = 'image'
    Info = 'info'
    Video = 'video'
    Audio = 'audio'
  end

  def toggle_approve!
    update_attribute :approved, !self.approved?
  end

  def transliteration?
    sub_type == SubType::Transliteration
  end

  def translation?
    sub_type == SubType::Translation
  end

  def tafisr?
    sub_type == SubType::Tafsir
  end

  def chapter_info?
    sub_type == SubType::Info
  end

  def video?
    sub_type == SubType::Video
  end

  def recitation?
    sub_type == SubType::Audio || resource_type == ResourceType::Audio
  end

  class << self
    def collection_for_resource_type
      ResourceContent::ResourceType.constants.map do |c|
        ResourceContent::ResourceType.const_get c
      end
    end

    def collection_for_sub_type
      ResourceContent::SubType.constants.map do |c|
        ResourceContent::SubType.const_get c
      end
    end

    def collection_for_cardinality_type
      ResourceContent::CardinalityType.constants.map do |c|
        ResourceContent::CardinalityType.const_get c
      end
    end
  end
  
  protected
  def update_related_content
    if translation? && priority_changed?
       Translation.where(resource_content_id: id).update_all priority: priority
    end
  end
end
