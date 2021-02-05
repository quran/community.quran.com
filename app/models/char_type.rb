class CharType < QuranApiRecord
  belongs_to :parent, class_name: 'CharType'
  has_many :children, class_name: 'CharType', foreign_key: 'parent_id'

  def to_s
    name
  end
end
