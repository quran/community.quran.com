class WbwTranslation < ApplicationRecord
  belongs_to :word
  delegate :text_imlaei, :ur_translation, :en_translation, :location, :char_type_name, to: :word
end
