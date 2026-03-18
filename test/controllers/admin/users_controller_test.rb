require 'test_helper'

class Admin::UsersControllerTest < ActionDispatch::IntegrationTest
  test 'admin user cannot delete itself' do
    admin_user = users(:admin)
    sign_in admin_user

    assert_no_difference('User.count') do
      delete admin_user_path(admin_user)
    end

    assert_response :forbidden
    assert User.exists?(admin_user.id)
  end

  test 'admin user can delete another user' do
    admin_user = users(:admin)
    regular_user = users(:regular)
    sign_in admin_user

    assert_difference('User.count', -1) do
      delete admin_user_path(regular_user)
    end

    assert_redirected_to admin_users_path
    assert_not User.exists?(regular_user.id)
  end

  test 'admin user can toggle another user role to admin' do
    admin_user = users(:admin)
    regular_user = users(:regular)
    sign_in admin_user

    patch toggle_role_admin_user_path(regular_user)

    regular_user.reload
    assert_equal 'admin', regular_user.role
    assert_redirected_to admin_users_path
  end

  test 'admin user can toggle another user role to regular' do
    admin_user = users(:admin)
    another_admin = User.create!(
      name: 'Another Admin',
      email: 'another_admin@example.com',
      password: 'password123',
      role: 'admin'
    )
    sign_in admin_user

    patch toggle_role_admin_user_path(another_admin)

    another_admin.reload
    assert_equal 'regular', another_admin.role
    assert_redirected_to admin_users_path
  end

  test 'regular user cannot access users index' do
    sign_in users(:regular)

    get admin_users_path
    assert_response :forbidden
  end

  test 'regular user cannot delete user' do
    regular_user = users(:regular)
    admin_user = users(:admin)
    sign_in regular_user

    assert_no_difference('User.count') do
      delete admin_user_path(admin_user)
    end

    assert_response :forbidden
  end

  test 'regular user cannot toggle user role' do
    regular_user = users(:regular)
    another_user = User.create!(
      name: 'Test User',
      email: 'test@example.com',
      password: 'password123',
      role: 'regular'
    )
    sign_in regular_user

    patch toggle_role_admin_user_path(another_user)
    assert_response :forbidden

    another_user.reload
    assert_equal 'regular', another_user.role
  end

  test 'unauthenticated user cannot access users index' do
    get admin_users_path
    assert_redirected_to new_user_session_path
  end

  test 'admin user can paginate through users' do
    admin_user = users(:admin)
    sign_in admin_user

    # Create 25 users to trigger pagination (20 per page)
    25.times do |i|
      User.create!(
        name: "User #{i}",
        email: "user#{i}@example.com",
        password: 'password123',
        role: 'regular'
      )
    end

    # First page
    get admin_users_path
    assert_response :success

    # Second page
    get admin_users_path, params: { page: 2 }
    assert_response :success
  end

  test 'admin user can search users by name' do
    admin_user = users(:admin)
    regular_user = users(:regular)
    sign_in admin_user

    User.create!(
      name: 'John Foobar',
      email: 'john@example.com',
      password: 'password123',
      role: 'regular'
    )

    User.create!(
      name: 'Jane Doe',
      email: 'jane@example.com',
      password: 'password123',
      role: 'regular'
    )

    get admin_users_path, params: { search: 'foo' }
    assert_response :success
    assert_select 'td', text: 'John Foobar'
    assert_select 'td', text: 'jane@example.com', count: 0
  end

  test 'admin user can search users by email' do
    admin_user = users(:admin)
    sign_in admin_user

    User.create!(
      name: 'John Doe',
      email: 'john@foobar.com',
      password: 'password123',
      role: 'regular'
    )

    User.create!(
      name: 'Jane Doe',
      email: 'jane@example.com',
      password: 'password123',
      role: 'regular'
    )

    get admin_users_path, params: { search: 'foobar' }
    assert_response :success
    assert_select 'td', text: 'john@foobar.com'
    assert_select 'td', text: 'jane@example.com', count: 0
  end

  test 'admin user search is case insensitive' do
    admin_user = users(:admin)
    sign_in admin_user

    User.create!(
      name: 'John Foobar',
      email: 'john@example.com',
      password: 'password123',
      role: 'regular'
    )

    get admin_users_path, params: { search: 'FOO' }
    assert_response :success
    assert_select 'td', text: 'John Foobar'
  end

  test 'admin user can access edit page for another user' do
    admin_user = users(:admin)
    regular_user = users(:regular)
    sign_in admin_user

    get edit_admin_user_path(regular_user)
    assert_response :success
  end

  test 'admin user can update another user' do
    admin_user = users(:admin)
    regular_user = users(:regular)
    sign_in admin_user

    assert_no_enqueued_emails do
      patch admin_user_path(regular_user), params: {
        user: { name: 'Updated Name', email: 'updated@example.com' }
      }
    end

    regular_user.reload
    assert_equal 'Updated Name', regular_user.name
    assert_equal 'updated@example.com', regular_user.email
    assert_redirected_to admin_users_path
  end

  test 'admin user can update another user password' do
    admin_user = users(:admin)
    regular_user = users(:regular)
    sign_in admin_user

    assert_enqueued_emails 1 do
      patch admin_user_path(regular_user), params: {
        user: { password: 'newpassword123', password_confirmation: 'newpassword123' }
      }
    end

    regular_user.reload
    assert regular_user.valid_password?('newpassword123')
    assert_redirected_to admin_users_path
  end

  test 'admin user update without password leaves password unchanged' do
    admin_user = users(:admin)
    regular_user = users(:regular)
    old_encrypted_password = regular_user.encrypted_password
    sign_in admin_user

    assert_no_enqueued_emails do
      patch admin_user_path(regular_user), params: {
        user: { name: 'Updated Name', password: '', password_confirmation: '' }
      }
    end

    regular_user.reload
    assert_equal 'Updated Name', regular_user.name
    assert_equal old_encrypted_password, regular_user.encrypted_password
    assert_redirected_to admin_users_path
  end

  test 'regular user cannot access edit page' do
    regular_user = users(:regular)
    another_user = User.create!(
      name: 'Test User',
      email: 'testedit@example.com',
      password: 'password123',
      role: 'regular'
    )
    sign_in regular_user

    get edit_admin_user_path(another_user)
    assert_response :forbidden
  end

  test 'regular user cannot update another user' do
    regular_user = users(:regular)
    another_user = User.create!(
      name: 'Test User',
      email: 'testupdate@example.com',
      password: 'password123',
      role: 'regular'
    )
    sign_in regular_user

    patch admin_user_path(another_user), params: {
      user: { name: 'Hacked Name' }
    }

    another_user.reload
    assert_equal 'Test User', another_user.name
    assert_response :forbidden
  end
end
