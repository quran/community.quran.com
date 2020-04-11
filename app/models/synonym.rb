class Synonym < ApplicationRecord
  serialize :synonyms, Array

  has_many :word_synonyms
  has_many :words, through: :word_synonyms
end
