class Users::ProfilesController < ApplicationController
  before_action :set_user

  def edit
    @notification_preferences = @user.notification_preferences
    @api_key_summary = @user.api_key_summary
    @team_summary = @user.team_summary
  end

  def update
    if @user.update(profile_params)
      flash[:success] = "Profile updated successfully"
      log_activity('profile_updated', @user)
      redirect_to edit_users_profile_path
    else
      flash[:error] = "Failed to update profile"
      @notification_preferences = @user.notification_preferences
      @api_key_summary = @user.api_key_summary
      @team_summary = @user.team_summary
      render :edit
    end
  end

  def change_password
    if @user.update_with_password(password_params)
      flash[:success] = "Password changed successfully"
      log_activity('password_changed', @user)
      redirect_to edit_users_profile_path
    else
      flash[:error] = "Failed to change password"
      redirect_to edit_users_profile_path
    end
  end

  def enable_mfa
    if @user.enable_mfa!
      flash[:success] = "Two-factor authentication enabled"
      log_activity('mfa_enabled', @user)
    else
      flash[:error] = "Failed to enable two-factor authentication"
    end

    redirect_to edit_users_profile_path
  end

  def disable_mfa
    if @user.disable_mfa!
      flash[:success] = "Two-factor authentication disabled"
      log_activity('mfa_disabled', @user)
    else
      flash[:error] = "Failed to disable two-factor authentication"
    end

    redirect_to edit_users_profile_path
  end

  def regenerate_backup_codes
    codes = @user.generate_new_backup_codes
    
    if codes
      flash[:success] = "Backup codes regenerated successfully"
      log_activity('backup_codes_regenerated', @user)
      
      # In a real app, you'd want to show these codes to the user securely
      # For now, we'll just confirm they were generated
    else
      flash[:error] = "Failed to regenerate backup codes"
    end

    redirect_to edit_users_profile_path
  end

  private

  def set_user
    @user = current_user
  end

  def profile_params
    params.require(:user).permit(
      :first_name, :last_name, :timezone, :language,
      :email_notifications, :alert_notifications, :team_notifications
    )
  end

  def password_params
    params.require(:user).permit(:current_password, :password, :password_confirmation)
  end
end 