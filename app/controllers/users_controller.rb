class UsersController < ApplicationController
  before_action :logged_in_user, except: [:show, :create, :new]
  before_action :load_user, except: [:create, :new, :index]
  before_action :correct_user, only: [:edit, :update]
  before_action :admin_user, only: :destroy

  def index
    @users = User.activated.paginate page: params[:page],
      per_page: Settings.users.limit
  end

  def new
    @user = User.new
  end

  def show
    redirect_to root_path && return unless User.where(actiavted: true)
    @microposts = @user.microposts.sort_created.paginate page: params[:page],
      per_page: Settings.microposts.limit
  end

  def create
    @user = User.new user_params
    if @user.save
      @user.send_activation_email
      flash[:info] = t "users.create.check_email"
      redirect_to root_path
    else
      render :new
    end
  end

  def edit; end

  def following
    @title = t ".title_following"
    @users = @user.following.paginate(page: params[:page])
    render :show_follow
  end

  def followers
    @title = t ".title_followers"
    @users = @user.followers.paginate(page: params[:page])
    render :show_follow
  end

  def update
    if @user.update_attributes user_params
      flash[:success] = t "users.update.success"
      redirect_to @user
    else
      render :edit
    end
  end

  def destroy
    if @user.destroy
      flash[:success] = t "users.delete.success", id: params[:id]
    else
      flash[:warning] = t "users.delete.fail", id: params[:id]
    end
    redirect_to request.referer
  end

  private

  def admin_user
    redirect_to(root_path) unless current_user.admin?
  end

  def correct_user
    redirect_to(root_path) unless current_user?(@user)
  end

  def load_user
    @user = User.find_by id: params[:id]
    return if @user
    flash[:warning] = t("users.find.fail", id: params[:id])
    redirect_to root_path
  end

  def user_params
    params.require(:user).permit(:name, :email,
      :password, :password_confirmation)
  end
end
