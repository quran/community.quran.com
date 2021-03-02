class CommunityController < ApplicationController
  before_action :authenticate_user!
  before_action :set_paper_trail_whodunnit
  
  def splash
  end
  
  protected
  def user_for_paper_trail
    current_user.try(:id) || current_user.try(:email)
  end
end
