require 'test_helper'

class Api::ProfilesControllerTest < ActionDispatch::IntegrationTest
  test 'show returns user profile' do
    user = users(:regular)
    sign_in user

    get '/api/profile', as: :json

    assert_response :success
    json_response = JSON.parse(response.body)
    assert json_response['user'].present?
    assert_equal user.email, json_response['user']['email']
    assert_equal user.name, json_response['user']['name']
    assert_equal user.role, json_response['user']['role']
  end

  test 'show requires authentication' do
    get '/api/profile', as: :json

    assert_response :unauthorized
  end

  test 'update requires authentication' do
    patch '/api/profile', params: { user: { name: 'New Name' } }, as: :json

    assert_response :unauthorized
  end

  test 'update changes user name' do
    user = users(:regular)
    sign_in user

    patch '/api/profile', params: { user: { name: 'Updated Name' } }, as: :json

    assert_response :success
    user.reload
    assert_equal 'Updated Name', user.name

    json_response = JSON.parse(response.body)
    assert_equal 'Updated Name', json_response['user']['name']
  end

  test 'update uploads avatar' do
    user = users(:regular)
    sign_in user
    avatar_file = fixture_file_upload('avatar_valid.jpg', 'image/jpeg')

    patch '/api/profile', params: { user: { avatar: avatar_file } }

    assert_response :success
    user.reload
    assert user.avatar.attached?

    json_response = JSON.parse(response.body)
    assert_not_nil json_response['user']['avatar_url']
  end

  test 'update deletes avatar when empty string is passed' do
    user = users(:regular)
    user.avatar.attach(
      io: File.open(Rails.root.join('test/fixtures/files/avatar_valid.jpg')),
      filename: 'avatar.jpg',
      content_type: 'image/jpeg'
    )
    assert user.avatar.attached?
    sign_in user

    patch '/api/profile', params: { user: { avatar: '' } }, as: :json

    assert_response :success
    user.reload
    assert_not user.avatar.attached?

    json_response = JSON.parse(response.body)
    assert_nil json_response['user']['avatar_url']
  end

  test 'update deletes avatar when nil is passed' do
    user = users(:regular)
    user.avatar.attach(
      io: File.open(Rails.root.join('test/fixtures/files/avatar_valid.jpg')),
      filename: 'avatar.jpg',
      content_type: 'image/jpeg'
    )
    assert user.avatar.attached?
    sign_in user

    patch '/api/profile', params: { user: { avatar: nil } }, as: :json

    assert_response :success
    user.reload
    assert_not user.avatar.attached?
  end

  test 'update rejects avatar when plain data is passed instead of file' do
    user = users(:regular)
    sign_in user

    patch '/api/profile', params: { user: { avatar: 'some string data' } }, as: :json

    assert_response :unprocessable_entity
  end

  test 'update uploads avatar from base64 data URI' do
    user = users(:regular)
    sign_in user

    image_path = Rails.root.join('test/fixtures/files/avatar_valid.jpg')
    base64_data = Base64.strict_encode64(File.read(image_path))
    data_uri = "data:image/jpeg;base64,#{base64_data}"

    patch '/api/profile', params: { user: { avatar: data_uri } }, as: :json

    assert_response :success
    user.reload
    assert user.avatar.attached?

    json_response = JSON.parse(response.body)
    assert_not_nil json_response['user']['avatar_url']
  end

  test 'update rejects avatar with invalid format' do
    user = users(:regular)
    sign_in user
    invalid_file = fixture_file_upload('test.txt', 'text/plain')

    patch '/api/profile', params: { user: { avatar: invalid_file } }

    assert_response :unprocessable_entity
    user.reload
    assert_not user.avatar.attached?

    json_response = JSON.parse(response.body)
    assert_includes json_response['errors']['avatar'].first, 'is not a valid image'
  end

  test 'update can change name and upload avatar simultaneously' do
    user = users(:regular)
    sign_in user
    avatar_file = fixture_file_upload('avatar_valid.jpg', 'image/jpeg')

    patch '/api/profile', params: { user: { name: 'New Name', avatar: avatar_file } }

    assert_response :success
    user.reload
    assert_equal 'New Name', user.name
    assert user.avatar.attached?
  end

  test 'update returns validation error for blank name' do
    user = users(:regular)
    sign_in user

    patch '/api/profile', params: { user: { name: '' } }, as: :json

    assert_response :unprocessable_entity
    user.reload
    assert_not_equal '', user.name

    json_response = JSON.parse(response.body)
    assert json_response['errors'].any? { |e| e.include?('Name') }
  end
end
