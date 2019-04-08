class WbwTranslation < ApplicationRecord
  belongs_to :word
  belongs_to :language

  delegate :text_imlaei, :ur_translation, :en_translation, :location, :char_type_name, to: :word
end
