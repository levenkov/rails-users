require 'test_helper'

class UserTest < ActiveSupport::TestCase
  test 'user with ROOT_USER_ID gets admin role automatically' do
    user = User.create!(
      name: 'Test User',
      email: "test#{SecureRandom.hex(4)}@example.com",
      password: 'password123'
    )

    User.send(:remove_const, :ROOT_USER_ID)
    User.const_set(:ROOT_USER_ID, user.id)

    user.send(:assign_admin_to_first_user)

    user.reload
    assert_equal 'admin', user.role
    assert user.admin?

    User.send(:remove_const, :ROOT_USER_ID)
    User.const_set(:ROOT_USER_ID, 1)
  end

  test 'users with IDs different from ROOT_USER_ID get regular role by default' do
    User.send(:remove_const, :ROOT_USER_ID)
    User.const_set(:ROOT_USER_ID, -1)

    user = User.create!(
      name: 'Regular User',
      email: "regular#{SecureRandom.hex(4)}@example.com",
      password: 'password123'
    )

    assert_equal 'regular', user.role
    assert user.regular?

    User.send(:remove_const, :ROOT_USER_ID)
    User.const_set(:ROOT_USER_ID, 1)
  end

  test 'role can be manually changed after creation' do
    user = User.create!(
      name: 'Test User',
      email: "test#{SecureRandom.hex(4)}@example.com",
      password: 'password123'
    )

    user.update!(role: :regular)
    assert user.regular?

    user.update!(role: :admin)
    assert user.admin?
  end

  test 'disabled user is not active for authentication' do
    user = User.create!(
      name: 'Test User',
      email: "test#{SecureRandom.hex(4)}@example.com",
      password: 'password123',
      disabled: true
    )

    assert_equal false, user.active_for_authentication?
    assert_equal :disabled, user.inactive_message
  end

  test 'enabled user is active for authentication' do
    user = User.create!(
      name: 'Test User',
      email: "test#{SecureRandom.hex(4)}@example.com",
      password: 'password123',
      disabled: false
    )

    assert_equal true, user.active_for_authentication?
  end

  test 'accepts valid avatar image' do
    user = User.create!(
      name: 'Test User',
      email: "test#{SecureRandom.hex(4)}@example.com",
      password: 'password123'
    )

    user.avatar.attach(
      io: StringIO.new('fake image data'),
      filename: 'avatar.jpg',
      content_type: 'image/jpeg'
    )

    assert user.valid?
    assert user.avatar.attached?
  end

  test 'rejects avatar with invalid content type' do
    user = User.create!(
      name: 'Test User',
      email: "test#{SecureRandom.hex(4)}@example.com",
      password: 'password123'
    )

    user.avatar.attach(
      io: StringIO.new('text content'),
      filename: 'avatar.txt',
      content_type: 'text/plain'
    )

    assert_not user.valid?
    assert_includes user.errors[:avatar], 'must be a PNG, JPEG, or WebP image'
  end
end
