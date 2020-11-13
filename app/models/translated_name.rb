class TranslatedName < QuranApiRecord
  belongs_to :language
  belongs_to :resource, polymorphic: true

  after_save :fix_priority

  protected

  def fix_priority
    if language&.name == 'English'
      update_columns language_priority: 1, language_name: 'english'
    else
      update_columns language_priority: 3, language_name: language&.name.downcase
    end
  end
end
