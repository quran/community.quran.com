class ProofReadComment < ApplicationRecord
  belongs_to :user
  belongs_to :resource, polymorphic: true
end
