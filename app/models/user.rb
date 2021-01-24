class User < ApplicationRecord
  devise :database_authenticatable, :registerable, :lockable,
         :rememberable, :trackable, :validatable

  validates :first_name, :last_name, presence: true

  has_many :user_projects

  def active_for_authentication?
    approved?
  end
end
