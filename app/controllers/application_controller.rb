class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Authentication
  before_action :authenticate_user!
  before_action :ensure_user_confirmed!
  before_action :ensure_user_not_locked!
  before_action :set_current_user
  before_action :set_audit_user
  before_action :set_user_and_company

  # Authorization
  before_action :check_permissions

  # Error handling
  rescue_from ActiveRecord::RecordNotFound, with: :not_found
  rescue_from ActionController::ParameterMissing, with: :bad_request
  rescue_from Pundit::NotAuthorizedError, with: :forbidden

  # Flash messages
  add_flash_types :success, :error, :warning, :info

  private

  def set_current_user
    Current.user = current_user
    Current.user_agent = request.user_agent
    Current.ip_address = request.remote_ip
  end

  def set_audit_user
    # Set current user for audit purposes if using paper_trail gem
    # This is a no-op if paper_trail isn't installed
    if defined?(PaperTrail) && PaperTrail.respond_to?(:request)
      PaperTrail.request.whodunnit = current_user&.id
    end
  rescue => e
    Rails.logger.debug "PaperTrail not available: #{e.message}"
  end

  def ensure_user_confirmed!
    return unless user_signed_in?
    return if current_user.confirmed_at.present?
    return if devise_controller?

    flash[:warning] = "Please confirm your email address to access all features."
    redirect_to profile_path unless controller_name == 'dashboard' && action_name == 'profile'
  end

  def ensure_user_not_locked!
    return unless user_signed_in?
    return unless current_user.locked?

    sign_out current_user
    flash[:error] = "Your account has been locked. Please contact support."
    redirect_to new_user_session_path
  end

  def check_permissions
    return unless user_signed_in?
    return if devise_controller?
    return if controller_name == 'dashboard'

    # Check if user has permission to access the current resource
    resource = controller_name.singularize
    action = action_name

    unless current_user.can_access?(resource, action)
      flash[:error] = "You don't have permission to access this resource."
      redirect_to dashboard_path
    end
  end

  def require_admin!
    return if current_user&.admin?

    flash[:error] = "Admin access required."
    redirect_to dashboard_path
  end

  def require_team_access!
    return if current_user&.team.present?

    flash[:error] = "Team access required."
    redirect_to dashboard_path
  end

  def not_found(exception)
    respond_to do |format|
      format.html { render 'errors/not_found', status: :not_found }
      format.json { render json: { error: 'Resource not found' }, status: :not_found }
    end
  end

  def bad_request(exception)
    respond_to do |format|
      format.html { render 'errors/bad_request', status: :bad_request }
      format.json { render json: { error: exception.message }, status: :bad_request }
    end
  end

  def forbidden(exception)
    respond_to do |format|
      format.html { render 'errors/forbidden', status: :forbidden }
      format.json { render json: { error: 'Access denied' }, status: :forbidden }
    end
  end

  def sanitize_params(params, allowed_keys)
    params.permit(allowed_keys)
  end

  def respond_with_json(data, status: :ok)
    render json: data, status: status
  end

  def respond_with_error(message, status: :unprocessable_entity)
    render json: { error: message }, status: status
  end

  def set_user_and_company
    @user = current_user
    @company = current_user&.company
  end
end
