class ImportantNote < ApplicationRecord
  belongs_to :verse, optional: true
  belongs_to :word, optional: true
  belongs_to :admin_user
end
