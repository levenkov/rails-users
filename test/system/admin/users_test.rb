require 'application_system_test_case'

module Admin
  class UsersTest < ApplicationSystemTestCase
    setup do
      @admin = users(:admin)
      @regular_user = users(:regular)
      sign_in_as(@admin)
    end

    # Index page tests

    test 'displays users list' do
      visit admin_users_path

      assert_selector '#user-search'
      assert_selector "tr#user-row-#{@admin.id}"
      assert_selector "tr#user-row-#{@regular_user.id}"
    end

    test 'displays admin badge for admin users' do
      visit admin_users_path

      within("#user-row-#{@admin.id}") do
        assert_selector '[data-role="admin"]'
      end
    end

    test 'displays regular badge for regular users' do
      visit admin_users_path

      within("#user-row-#{@regular_user.id}") do
        assert_selector '[data-role="regular"]'
      end
    end

    test 'displays active status for enabled users' do
      visit admin_users_path

      within("#user-row-#{@regular_user.id}") do
        assert_selector '[data-status="active"]'
      end
    end

    test 'displays disabled status for disabled users' do
      @regular_user.update!(disabled: true)
      visit admin_users_path

      within("#user-row-#{@regular_user.id}") do
        assert_selector '[data-status="disabled"]'
      end
    end

    # Search tests

    test 'search filters users' do
      unique_user = User.create!(
        name: 'UniqueSearchName',
        email: 'uniquesearch@example.com',
        password: 'password123'
      )

      visit admin_users_path(search: 'UniqueSearch')

      assert_selector "#user-row-#{unique_user.id}"
      assert_no_selector "#user-row-#{@regular_user.id}"
    end

    # User menu tests

    test 'user menu button exists' do
      visit admin_users_path

      within("#user-row-#{@regular_user.id}") do
        assert_selector ".user-menu-button[data-user-id='#{@regular_user.id}']", visible: :all
      end
    end

    test 'clicking user menu shows dropdown' do
      visit admin_users_path

      within("#user-row-#{@regular_user.id}") do
        find('.user-menu-button', visible: :all).click
      end

      assert_selector ".user-menu[data-user-id='#{@regular_user.id}']:not(.hidden)"
    end

    test 'edit link navigates to edit page' do
      visit admin_users_path

      within("#user-row-#{@regular_user.id}") do
        find('.user-menu-button', visible: :all).click
      end

      within(".user-menu[data-user-id='#{@regular_user.id}']") do
        click_link href: edit_admin_user_path(@regular_user)
      end

      assert_current_path edit_admin_user_path(@regular_user)
    end

    test 'toggle role changes user from regular to admin' do
      visit admin_users_path

      within("#user-row-#{@regular_user.id}") do
        assert_selector '[data-role="regular"]'
        find('.user-menu-button', visible: :all).click
      end

      within(".user-menu[data-user-id='#{@regular_user.id}']") do
        click_link href: toggle_role_admin_user_path(@regular_user)
      end

      # Wait for the role badge to change to admin
      within("#user-row-#{@regular_user.id}") do
        assert_selector '[data-role="admin"]', wait: 5
      end

      @regular_user.reload
      assert_equal 'admin', @regular_user.role
    end

    test 'delete user removes user' do
      user_to_delete = User.create!(
        name: 'User To Delete',
        email: 'delete_me@example.com',
        password: 'password123'
      )

      visit admin_users_path

      within("#user-row-#{user_to_delete.id}") do
        find('.user-menu-button', visible: :all).click
      end

      within(".user-menu[data-user-id='#{user_to_delete.id}']") do
        accept_confirm do
          click_link href: admin_user_path(user_to_delete)
        end
      end

      assert_current_path admin_users_path
      assert_no_selector "#user-row-#{user_to_delete.id}"
      assert_not User.exists?(user_to_delete.id)
    end

    # Edit page tests

    test 'edit page displays user form' do
      visit edit_admin_user_path(@regular_user)

      assert_field 'user_name', with: @regular_user.name
      assert_field 'user_email', with: @regular_user.email
    end

    test 'updating user name saves changes' do
      visit edit_admin_user_path(@regular_user)

      fill_in 'user_name', with: 'Updated Name'
      click_button 'Update User'

      assert_current_path admin_users_path
      @regular_user.reload
      assert_equal 'Updated Name', @regular_user.name
    end

    test 'updating user email saves changes' do
      visit edit_admin_user_path(@regular_user)

      fill_in 'user_email', with: 'updated@example.com'
      click_button 'Update User'

      assert_current_path admin_users_path
      @regular_user.reload
      assert_equal 'updated@example.com', @regular_user.email
    end

    test 'disabling user account' do
      visit edit_admin_user_path(@regular_user)

      check 'user_disabled'
      click_button 'Update User'

      assert_current_path admin_users_path
      @regular_user.reload
      assert @regular_user.disabled
    end

    test 'changing user password' do
      visit edit_admin_user_path(@regular_user)

      fill_in 'user_password', with: 'newpassword123'
      fill_in 'user_password_confirmation', with: 'newpassword123'
      click_button 'Change Password'

      assert_current_path admin_users_path
      @regular_user.reload
      assert @regular_user.valid_password?('newpassword123')
    end

    test 'cancel returns to users list' do
      visit edit_admin_user_path(@regular_user)

      within('.bg-white.shadow.rounded-lg', match: :first) do
        click_link href: admin_users_path
      end

      assert_current_path admin_users_path
    end

    private

    def sign_in_as(user)
      visit new_user_session_path
      fill_in 'user-email-field', with: user.email
      fill_in 'user-password-field', with: 'password123'
      find('#sign-in-button').click

      # Wait for redirect to complete, then navigate to users page
      assert_selector '#admin-panel-title', wait: 5
      visit admin_users_path
      assert_selector '#user-search', wait: 5
    end
  end
end
