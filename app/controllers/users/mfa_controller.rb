class Users::MfaController < ApplicationController
  before_action :require_pending_mfa_user
  before_action :set_user

  def new
    # Show MFA verification form
  end

  def create
    code = params[:mfa_code]

    if @user.verify_two_factor_code(code)
      # MFA successful, complete login
      sign_in(@user)

      if session[:pending_mfa_remember_me] == "1"
        @user.remember_me!
      end

      # Clear session data
      session.delete(:pending_mfa_user_id)
      session.delete(:pending_mfa_remember_me)

      # Record successful login
      @user.record_login(request.remote_ip)

      AuditLog.create!(
        user: @user,
        action: "user_login_success",
        resource_type: "User",
        resource_id: @user.id,
        ip_address: request.remote_ip,
        user_agent: request.user_agent,
        details: { method: "password_with_mfa" }
      )

      redirect_to after_sign_in_path_for(@user), notice: "Successfully signed in!"
    else
      flash.now[:alert] = "Invalid MFA code. Please try again."
      render :new
    end
  rescue => e
    Rails.logger.error "MFA verification error: #{e.message}"
    flash.now[:alert] = "An error occurred during MFA verification."
    render :new
  end

  def backup_code
    code = params[:backup_code]

    if @user.verify_backup_code(code)
      # Backup code successful, complete login
      sign_in(@user)

      if session[:pending_mfa_remember_me] == "1"
        @user.remember_me!
      end

      # Clear session data
      session.delete(:pending_mfa_user_id)
      session.delete(:pending_mfa_remember_me)

      # Record successful login
      @user.record_login(request.remote_ip)

      AuditLog.create!(
        user: @user,
        action: "user_login_success",
        resource_type: "User",
        resource_id: @user.id,
        ip_address: request.remote_ip,
        user_agent: request.user_agent,
        details: { method: "backup_code" }
      )

      redirect_to after_sign_in_path_for(@user), notice: "Successfully signed in with backup code!"
    else
      flash.now[:alert] = "Invalid backup code. Please try again."
      render :new
    end
  rescue => e
    Rails.logger.error "Backup code verification error: #{e.message}"
    flash.now[:alert] = "An error occurred during backup code verification."
    render :new
  end

  private

  def require_pending_mfa_user
    unless session[:pending_mfa_user_id]
      redirect_to new_user_session_path, alert: "Please sign in first."
    end
  end

  def set_user
    @user = User.find(session[:pending_mfa_user_id])
  rescue ActiveRecord::RecordNotFound
    session.delete(:pending_mfa_user_id)
    session.delete(:pending_mfa_remember_me)
    redirect_to new_user_session_path, alert: "Invalid session. Please sign in again."
  end

  def after_sign_in_path_for(resource)
    if resource.admin?
      admin_dashboard_path
    else
      dashboard_path
    end
  end
end
