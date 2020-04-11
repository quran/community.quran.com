class WordSynonym < ApplicationRecord
  belongs_to :word
  belongs_to :synonym
end
