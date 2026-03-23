class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
    :recoverable, :rememberable, :validatable,
    :jwt_authenticatable, :omniauthable,
    jwt_revocation_strategy: Devise::JWT::RevocationStrategies::Null,
    omniauth_providers: %i[google_oauth2_ios]

  include SimpleEnumerable

  ROOT_USER_ID = 1
  AVATAR_CONTENT_TYPES = %w[image/png image/jpeg image/webp].freeze
  AVATAR_PROCESSED_SIZE = 128

  simple_enum :role, :admin, default: :regular

  has_many :user_oauths, dependent: :destroy
  has_many :notes, dependent: :destroy
  has_many :note_tags, dependent: :destroy
  has_one_attached :avatar

  validates :name, presence: true
  validate :validate_avatar_content_type

  after_create :assign_admin_to_first_user

  def active_for_authentication?
    super && !disabled
  end

  def inactive_message
    disabled ? :disabled : super
  end

  private

  def assign_admin_to_first_user
    if id == self.class::ROOT_USER_ID
      update_columns(role: 'admin')
    end
  end

  def validate_avatar_content_type
    return unless avatar.attached?
    return if attachment_changes['avatar'].nil?

    unless avatar.content_type.in?(AVATAR_CONTENT_TYPES)
      errors.add(:avatar, 'must be a PNG, JPEG, or WebP image')
    end
  end
end
