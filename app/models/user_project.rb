class UserProject < ApplicationRecord
  include Resourceable

  belongs_to :user
end
