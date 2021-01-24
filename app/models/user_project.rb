class UserProject < ApplicationRecord
  belongs_to :user
  belongs_to :resource_content
end
