class Admin::ApiKeysController < ApplicationController
  before_action :authenticate_user!
  before_action :ensure_admin!
  before_action :set_api_key, only: [:show, :destroy]

  def index
    @api_keys = ApiKey.includes(:company).order(created_at: :desc)
  end

  def show
  end

  def destroy
    if @api_key.destroy
      flash[:success] = "API key deleted successfully"
    else
      flash[:error] = "Failed to delete API key"
    end
    redirect_to admin_api_keys_path
  end

  private

  def ensure_admin!
    unless current_user.admin?
      flash[:error] = "Access denied. Admin privileges required."
      redirect_to dashboard_path
    end
  end

  def set_api_key
    @api_key = ApiKey.find(params[:id])
  end
end 