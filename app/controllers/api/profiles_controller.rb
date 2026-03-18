require 'mini_magick'

class Api::ProfilesController < ApplicationController
  AVATAR_MAX_FILE_SIZE = 12.megabytes
  AVATAR_MAX_DIMENSION = 4032

  before_action :authenticate_user!
  before_action :validate_avatar!, only: :update, if: :avatar_passed?

  def show
    sleep 1 if Rails.env.development?
  end

  def update
    handle_avatar_deletion if should_delete_avatar?

    if avatar_passed? and avatar_param_type_is_valid?
      current_user.avatar.attach(AvatarProcessor.new(avatar_file).process)
    end

    if current_user.update(user_params)
      render :show, status: :ok
    else
      render json: { errors: current_user.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  def user_params
    params.require(:user).permit(:name)
  end

  def avatar_file
    @avatar_file ||= begin
      raw = params[:user][:avatar]
      if raw.is_a?(String) && raw.start_with?('data:')
        decode_base64_avatar(raw)
      else
        raw
      end
    end
  end

  def decode_base64_avatar(data_uri)
    match = data_uri.match(/\Adata:(\w+\/\w+);base64,(.+)\z/m)
    return nil unless match

    content_type = match[1]
    encoded_data = match[2]
    extension = content_type.split('/').last

    tempfile = Tempfile.new([ 'avatar', ".#{extension}" ])
    tempfile.binmode
    tempfile.write(Base64.decode64(encoded_data))
    tempfile.rewind

    ActionDispatch::Http::UploadedFile.new(
      tempfile: tempfile,
      filename: "avatar.#{extension}",
      type: content_type
    )
  end

  def avatar_passed?
    params[:user][:avatar].present?
  end

  def avatar_param_type_is_valid?
    avatar_file&.respond_to?(:tempfile)
  end

  def should_delete_avatar?
    params[:user].key?(:avatar) && params[:user][:avatar].blank?
  end

  def handle_avatar_deletion
    current_user.avatar.purge if current_user.avatar.attached?
  end

  def validate_avatar!
    unless avatar_param_type_is_valid?
      return render json: { errors: { avatar: [ 'param is not valid' ] } }, status: :unprocessable_entity
    end

    file = avatar_file

    if file.size > AVATAR_MAX_FILE_SIZE
      return render(
        json: {
          errors: {
            avatar: [ "must be less than #{AVATAR_MAX_FILE_SIZE / 1.megabyte} MB" ],
          },
        },
        status: :unprocessable_entity,
      )
    end

    image = MiniMagick::Image.new(file.tempfile.path)
    if image.width > AVATAR_MAX_DIMENSION || image.height > AVATAR_MAX_DIMENSION
      render(
        json: {
          errors: {
            avatar: [ "dimensions must not exceed #{AVATAR_MAX_DIMENSION}x#{AVATAR_MAX_DIMENSION} pixels" ],
          },
        },
        status: :unprocessable_entity,
      )
    end
  rescue MiniMagick::Error
    render json: { errors: { avatar: [ 'is not a valid image' ] } }, status: :unprocessable_entity
  end
end
