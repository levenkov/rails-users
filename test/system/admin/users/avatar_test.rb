require 'application_system_test_case'

module Admin
  module Users
    class AvatarTest < ApplicationSystemTestCase
      setup do
        @admin = users(:admin)
        @regular_user = users(:regular)
        sign_in_as(@admin)
      end

      test 'edit page displays avatar upload section' do
        visit edit_admin_user_path(@regular_user)

        assert_selector 'h2', text: 'Profile Picture'
        assert_selector 'input[type="file"][name="user[avatar]"]'
      end

      test 'uploading valid avatar attaches it to user' do
        visit edit_admin_user_path(@regular_user)

        attach_file 'user[avatar]', Rails.root.join('test/fixtures/files/avatar_valid.jpg')
        click_button 'Upload Avatar'

        assert_text 'Avatar has been updated', wait: 5
        @regular_user.reload
        assert @regular_user.avatar.attached?
      end

      test 'uploading avatar with dimensions too large shows error' do
        visit edit_admin_user_path(@regular_user)

        attach_file 'user[avatar]', Rails.root.join('test/fixtures/files/test_image.jpg')
        click_button 'Upload Avatar'

        assert_selector '.text-red-600', text: 'uploading file should not be greater than 512x512'
      end

      test 'uploading avatar with invalid format shows error' do
        visit edit_admin_user_path(@regular_user)

        attach_file 'user[avatar]', Rails.root.join('test/fixtures/files/test.txt'), make_visible: true
        click_button 'Upload Avatar'

        assert_selector '.text-red-600', text: 'is not a valid image'
      end

      test 'uploading avatar with file size too large shows error' do
        large_file = create_large_image_file(3.megabytes)

        visit edit_admin_user_path(@regular_user)

        attach_file 'user[avatar]', large_file.path
        click_button 'Upload Avatar'

        assert_selector '.text-red-600', text: 'must be less than 2 MB'
      ensure
        large_file&.close
        large_file&.unlink
      end

      test 'remove avatar button removes attached avatar' do
        @regular_user.avatar.attach(
          io: File.open(Rails.root.join('test/fixtures/files/avatar_valid.jpg')),
          filename: 'avatar.jpg',
          content_type: 'image/jpeg'
        )

        visit edit_admin_user_path(@regular_user)

        assert_selector 'a', text: 'Remove Avatar'

        accept_confirm do
          click_link 'Remove Avatar'
        end

        # Wait for Turbo to complete and flash message to appear
        assert_text 'Avatar has been removed', wait: 5
        @regular_user.reload
        assert_not @regular_user.avatar.attached?
      end

      test 'users index shows avatar when attached' do
        @regular_user.avatar.attach(
          io: File.open(Rails.root.join('test/fixtures/files/avatar_valid.jpg')),
          filename: 'avatar.jpg',
          content_type: 'image/jpeg'
        )

        visit admin_users_path

        within("#user-row-#{@regular_user.id}") do
          assert_selector 'img.rounded-full'
        end
      end

      test 'users index shows placeholder when no avatar' do
        visit admin_users_path

        within("#user-row-#{@regular_user.id}") do
          assert_selector '.rounded-full.bg-indigo-100'
        end
      end

      private

      def sign_in_as(user)
        visit new_user_session_path
        fill_in 'user-email-field', with: user.email
        fill_in 'user-password-field', with: 'password123'
        find('#sign-in-button').click

        assert_selector '#admin-panel-title', wait: 5
      end

      def create_large_image_file(size)
        file = Tempfile.new([ 'large_avatar', '.jpg' ])
        file.binmode
        file.write("\xFF\xD8\xFF\xE0") # JPEG header
        file.write("\x00" * (size - 4))
        file.rewind
        file
      end
    end
  end
end
