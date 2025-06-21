class Users::ProfilesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_user

  def edit
    @api_key_summary = @user.api_key_summary
  end

  def update
    if @user.update(profile_params)
      flash[:success] = "Profile updated successfully"
      redirect_to edit_profile_path
    else
      flash[:error] = "Failed to update profile"
      @api_key_summary = @user.api_key_summary
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def set_user
    @user = current_user
  end

  def profile_params
    params.require(:user).permit(
      :first_name, :last_name, :timezone, :language
    )
  end
end 