class Companies::ApiKeysController < ApplicationController
  before_action :require_admin!
  before_action :set_api_key, only: [:show, :destroy]

  def index
    @api_keys = @company.api_keys.order(created_at: :desc)
  end

  def new
    @api_key = @company.api_keys.build
  end

  def create
    @api_key = @company.api_keys.build(api_key_params)

    if @api_key.save
      redirect_to companies_api_keys_path, notice: 'API key created successfully.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def show
  end

  def destroy
    @api_key.destroy
    redirect_to companies_api_keys_path, notice: 'API key deleted successfully.'
  end

  private

  def set_api_key
    @api_key = @company.api_keys.find(params[:id])
  end

  def api_key_params
    params.require(:api_key).permit(:display_name, :description, :is_active)
  end
end 