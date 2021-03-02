class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception
  before_action :set_paper_trail_whodunnit

  protected

  def user_for_paper_trail
    current_admin_user.try(:id) || current_user.try(:email)
  end

  def can_manage?(resource)
    if resource
      current_user.user_projects.find_by(resource_content_id: resource.id)
    end
  end
end
