class ProfilesController < ApplicationController
  before_action :authenticate_user!

  def show
    @user = current_user
    authorize @user
  end

  def edit
    @user = current_user
    authorize @user
  end

  def update
    @user = current_user
    authorize @user

    if @user.update(user_params)
      redirect_to profile_path, notice: "Profile was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @user = current_user
    authorize @user

    if @user.destroy
      redirect_to root_path, notice: "Your account has been successfully deleted."
    else
      redirect_to profile_path, alert: "Failed to delete account: #{@user.errors.full_messages.join(', ')}"
    end
  end

  private

  def user_params
    permitted = [:full_name, :email, :password, :password_confirmation, :avatar_image]

    # Remove password fields if they are blank
    if params[:user][:password].blank? && params[:user][:password_confirmation].blank?
      params[:user].delete(:password)
      params[:user].delete(:password_confirmation)
    end

    params.require(:user).permit(permitted)
  end
end
