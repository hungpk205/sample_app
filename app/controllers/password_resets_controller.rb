class PasswordResetsController < ApplicationController
  before_action :load_user, :valid_user,
    :check_expiration, only: %i(edit update)

  def new; end

  def create
    @user = User.find_by email: params[:password_reset][:email].downcase
    if @user
      if @user.activated?
        @user.create_reset_digest
        @user.send_password_reset_email
        flash[:info] = t "password_resets.email.sent_email"
      else
        flash[:danger] = t ".not_activate_account"
      end
      redirect_to root_url
    else
      flash.now[:danger] = t "password_resets.email.not_found"
      render :new
    end
  end

  def edit; end

  def update
    if params[:user][:password].empty?
      @user.errors.add(:password, t(".empty_password"))
      render :edit
    elsif @user.update_attributes(user_params)
      log_in @user
      @user.update_attribute :reset_digest, nil
      flash[:success] = t ".success_reset"
      redirect_to @user
    else
      render :edit
    end
  end

  private
  def load_user
    @user = User.find_by email: params[:email]
    return if @user
    flash.now[:danger] = t "password_resets.load_user.not_found_user"
    redirect_to root_path
  end

  def valid_user
    return if @user&.activated? && @user.authenticated?(:reset, params[:id])
  end

  def user_params
    params.require(:user).permit(:password, :password_confirmation)
  end

  def check_expiration
    return unless @user.password_reset_expired?
    flash[:danger] = t "password_resets.check_expiration.expired_password"
    redirect_to new_password_reset_url
  end
end
