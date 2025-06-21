class UsersController < ApplicationController
  before_action :set_user, only: [:show, :edit, :update, :destroy, :deactivate, :activate]

  def index
    @users = current_user.company.users.order(:first_name)
  end

  def show
  end

  def new
    @user = current_user.company.users.build
  end

  def create
    @user = current_user.company.users.build(user_params)
    
    if @user.save
      # Send invitation email
      UserMailer.invitation(@user).deliver_later
      redirect_to users_path, notice: 'User invitation was sent successfully.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @user.update(user_params)
      redirect_to users_path, notice: 'User was successfully updated.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @user == current_user
      redirect_to users_path, alert: 'You cannot delete your own account.'
    else
      @user.destroy
      redirect_to users_path, notice: 'User was successfully deleted.'
    end
  end

  def deactivate
    if @user == current_user
      redirect_to users_path, alert: 'You cannot deactivate your own account.'
    else
      @user.update(is_active: false)
      redirect_to users_path, notice: 'User was successfully deactivated.'
    end
  end

  def activate
    @user.update(is_active: true)
    redirect_to users_path, notice: 'User was successfully activated.'
  end

  private

  def user_params
    params.require(:user).permit(
      :email, 
      :first_name, 
      :last_name, 
      :role_id,
      :timezone,
      :language
    )
  end

  def set_user
    @user = current_user.company.users.find(params[:id])
  end
end 