class Recitation < QuranApiRecord
  include Resourceable

  belongs_to :reciter
  belongs_to :recitation_style

  delegate :approved?, to: :resource_content

  scope :approved, -> { joins(:resource_content).where('resource_contents.approved = ?', true) }
  scope :un_approved, -> { joins(:resource_content).where('resource_contents.approved = ?', false) }
end
