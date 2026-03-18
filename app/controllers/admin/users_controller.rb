require 'mini_magick'

class Admin::UsersController < Admin::BaseController
  AVATAR_MAX_FILE_SIZE = 2.megabytes
  AVATAR_MAX_DIMENSION = 512

  before_action :set_user, only: %i[edit update toggle_role destroy delete_avatar]
  before_action :validate_avatar!, only: :update, if: :avatar_upload?

  def index
    @users = User.with_attached_avatar

    if params[:search].present?
      search_term = "%#{params[:search]}%"
      @users = @users.where('name ILIKE ? OR email ILIKE ?', search_term, search_term)
    end

    @users = @users.order(created_at: :desc)
                   .page(params[:page])
                   .per(20)
  end

  def edit
  end

  def update
    user_params_hash = user_params.to_h
    password_changed = user_params_hash[:password].present?

    if user_params_hash[:password].blank?
      user_params_hash.delete(:password)
      user_params_hash.delete(:password_confirmation)
    end

    if avatar_upload?
      user_params_hash.delete(:avatar)
      @user.avatar.attach(AvatarProcessor.new(avatar_file).process)
    end

    if @user.update(user_params_hash)
      if password_changed
        UserMailer.with(user: @user, changed_by: current_user).password_changed.deliver_later
      end

      if avatar_upload?
        redirect_to edit_admin_user_path(@user), notice: 'Avatar has been updated.'
      else
        redirect_to admin_users_path, notice: "User #{@user.name} has been updated."
      end
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def toggle_role
    if @user.role == 'admin'
      @user.update(role: 'regular')
      message = "#{@user.name} is now a regular user."
    else
      @user.update(role: 'admin')
      message = "#{@user.name} is now an admin."
    end

    redirect_to admin_users_path, notice: message
  end

  def destroy
    authorize @user

    @user.destroy!
    redirect_to admin_users_path, notice: "User #{@user.name} has been deleted."
  end

  def delete_avatar
    @user.avatar.purge
    redirect_to edit_admin_user_path(@user), notice: 'Avatar has been removed.'
  end

  private

  def set_user
    @user = User.find(params[:id])
  end

  def user_params
    params.require(:user).permit(:name, :email, :password, :password_confirmation, :disabled, :avatar)
  end

  def avatar_file
    params[:user][:avatar]
  end

  def avatar_upload?
    avatar_file.present? && avatar_file.respond_to?(:tempfile)
  end

  def validate_avatar!
    if avatar_file.size > AVATAR_MAX_FILE_SIZE
      @user.errors.add(:avatar, "must be less than #{AVATAR_MAX_FILE_SIZE / 1.megabyte} MB")
      return render :edit, status: :unprocessable_entity
    end

    image = MiniMagick::Image.new(avatar_file.tempfile.path)
    if image.width > AVATAR_MAX_DIMENSION || image.height > AVATAR_MAX_DIMENSION
      @user.errors.add(
        :avatar,
        "uploading file should not be greater than #{AVATAR_MAX_DIMENSION}x#{AVATAR_MAX_DIMENSION}",
      )
      render :edit, status: :unprocessable_entity
    end
  rescue MiniMagick::Error
    @user.errors.add(:avatar, 'is not a valid image')
    render :edit, status: :unprocessable_entity
  end
end
