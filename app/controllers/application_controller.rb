class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception
  before_action :set_paper_trail_whodunnit
  before_action :configure_permitted_parameters, if: :devise_controller?

  protected
  def user_for_paper_trail
    current_admin_user.try(:id) || current_user.try(:email)
  end

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [:first_name, :last_name])
  end

  def can_manage?(resource)
    current_user.user_projects.find_by(resource_content_id: resource.id)
  end
end
