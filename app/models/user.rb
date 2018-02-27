class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :confirmable, :lockable, :recoverable,
         :rememberable, :trackable, :validatable
  
  validates :first_name, :last_name, presence: true
end
