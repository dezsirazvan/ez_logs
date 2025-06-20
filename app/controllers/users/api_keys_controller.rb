class Users::ApiKeysController < ApplicationController
  before_action :set_api_key, only: [:destroy, :regenerate]

  def index
    @api_keys = current_user.company.api_keys.order(created_at: :desc)
  end

  def new
    @api_key = current_user.company.api_keys.build
  end

  def create
    @api_key = current_user.company.api_keys.build(api_key_params)
    @api_key.user = current_user

    if @api_key.save
      flash[:success] = "API key created successfully"
      log_activity('api_key_created', @api_key)
      redirect_to users_api_keys_path
    else
      flash[:error] = "Failed to create API key"
      render :new
    end
  end

  def destroy
    if @api_key.destroy
      flash[:success] = "API key deleted successfully"
      log_activity('api_key_deleted', @api_key)
    else
      flash[:error] = "Failed to delete API key"
    end

    redirect_to users_api_keys_path
  end

  def regenerate
    if @api_key.regenerate!
      flash[:success] = "API key regenerated successfully"
      log_activity('api_key_regenerated', @api_key)
    else
      flash[:error] = "Failed to regenerate API key"
    end

    redirect_to users_api_keys_path
  end

  private

  def set_api_key
    @api_key = current_user.company.api_keys.find(params[:id])
  end

  def api_key_params
    params.require(:api_key).permit(:name, :description, :permissions)
  end
end 