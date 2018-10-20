class Translation < QuranApiRecord
  belongs_to :resource, polymorphic: true
  belongs_to :language
  belongs_to :resource_content
  has_many :foot_notes, as: :resource

  has_paper_trail on: [:update], ignore: [:created_at, :updated_at]
  
  protected
  class << self
    def import_translations(params)
      language = Language.find(params[:language_id])
      data_source = DataSource.find(params[:data_source_id])
      author = Author.find(params[:author_id])
    
      resource_content = ResourceContent.where(data_source: data_source, cardinality_type: ResourceContent::CardinalityType::OneVerse, sub_type: ResourceContent::SubType::Translation, resource_type: ResourceContent::ResourceType::Content, language: language, author: author).first_or_create
      resource_content.author_name = author.name
      resource_content.name = author.name
      resource_content.language_name = language.name
      resource_content.approved = false #varify and approve after importing
      resource_content.slug = "#{language.iso_code}_#{author.name.underscore.gsub(/(\s)+/, ' ').gsub(' ', '_')}"
      resource_content.save
    
      lines = []
      params[:file].open.each_line do |line|
        lines << line.strip
      end
    
      if Verse.count != lines.count
        return [false, "Invalid file, file should have #{Verse.count} lines"]
      end
    
      Verse.unscoped.order('verse_index asc').each_with_index do |verse, i|
        trans = verse.translations.where(language: language, resource_content: resource_content).first_or_create
        trans.text = lines[i]
        trans.language_name = language.name
        trans.resource_name = resource_content.name
        trans.save
      end
    
      [true, resource_content]
    rescue Exception => e
      [false, e.message]
    end
  end
end
