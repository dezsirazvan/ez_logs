# frozen_string_literal: true

class Users::SessionsController < Devise::SessionsController
  before_action :configure_sign_in_params, only: [ :create ]
  before_action :set_current_user, only: [ :create ]

  # GET /resource/sign_in
  def new
    super
  end

  # POST /resource/sign_in
  def create
    user = User.find_by(email: params[:user][:email])

    if user&.locked?
      flash[:alert] = "Account is locked. Please contact an administrator."
      redirect_to new_user_session_path and return
    end

    if user&.require_mfa?
      # Store user ID in session for MFA verification
      session[:pending_mfa_user_id] = user.id
      session[:pending_mfa_remember_me] = params[:user][:remember_me]
      redirect_to new_user_mfa_path and return
    end

    super do |user|
      if user.persisted?
        user.record_login(request.remote_ip)
        AuditLog.create!(
          user: user,
          action: "user_login_success",
          resource_type: "User",
          resource_id: user.id,
          ip_address: request.remote_ip,
          user_agent: request.user_agent,
          details: { method: "password" }
        )
      end
    end
  rescue => e
    Rails.logger.error "Login error: #{e.message}"
    flash[:alert] = "An error occurred during login. Please try again."
    redirect_to new_user_session_path
  end

  # DELETE /resource/sign_out
  def destroy
    if current_user
      AuditLog.create!(
        user: current_user,
        action: "user_logout",
        resource_type: "User",
        resource_id: current_user.id,
        ip_address: request.remote_ip,
        user_agent: request.user_agent,
        details: { session_duration: session_duration }
      )
    end

    super
  rescue => e
    Rails.logger.error "Logout error: #{e.message}"
    super
  end

  protected

  def configure_sign_in_params
    devise_parameter_sanitizer.permit(:sign_in, keys: [ :email, :password, :remember_me ])
  end

  def set_current_user
    Current.user = User.find_by(email: params[:user][:email])
  end

  def session_duration
    return nil unless session[:login_time]

    login_time = Time.parse(session[:login_time])
    (Time.current - login_time).to_i
  end

  def after_sign_in_path_for(resource)
    if resource.admin?
      admin_dashboard_path
    else
      dashboard_path
    end
  end

  def after_sign_out_path_for(resource_or_scope)
    new_user_session_path
  end
end
