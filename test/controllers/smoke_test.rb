require 'test_helper'

class SmokeTest < ActionDispatch::IntegrationTest
  test 'root path redirects to login when unauthenticated' do
    get root_path
    assert_redirected_to new_user_session_path
  end

  test 'sign in page loads' do
    get new_user_session_path
    assert_response :success
  end

  test 'notes page loads when authenticated' do
    sign_in users(:admin)
    get notes_path
    assert_response :success
  end

  test 'note show page loads when authenticated' do
    sign_in users(:admin)
    get note_path(notes(:admin_note_one))
    assert_response :success
  end
end
