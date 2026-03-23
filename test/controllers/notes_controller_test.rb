require 'test_helper'

class NotesControllerTest < ActionDispatch::IntegrationTest
  test 'index requires authentication' do
    get notes_path
    assert_redirected_to new_user_session_path
  end

  test 'index returns notes sorted by order' do
    sign_in users(:admin)
    get notes_path
    assert_response :success
  end

  test 'index JSON returns order field' do
    sign_in users(:admin)
    get notes_path, as: :json
    assert_response :success

    data = JSON.parse(response.body)
    assert data.is_a?(Array)
    assert data.first.key?('order')
    orders = data.map { |n| n['order'] }
    assert_equal orders.sort, orders
  end

  test 'show returns note with order' do
    sign_in users(:admin)
    note = notes(:admin_note_one)
    get note_path(note), as: :json
    assert_response :success

    data = JSON.parse(response.body)
    assert_equal note.order, data['order']
    assert_equal note.title, data['title']
  end

  test 'create assigns default order' do
    sign_in users(:admin)
    admin = users(:admin)
    max_order = admin.notes.unscoped.where(user_id: admin.id).maximum(:order)

    assert_difference('Note.count', 1) do
      post notes_path, params: { note: { title: 'New Note', body: 'Content' } }, as: :json
    end

    assert_response :created
    data = JSON.parse(response.body)
    assert_equal max_order + 1000, data['order']
  end

  test 'update can change order' do
    sign_in users(:admin)
    note = notes(:admin_note_one)

    patch note_path(note), params: { note: { order: 5000 } }, as: :json
    assert_response :success

    note.reload
    assert_equal 5000, note.order
  end

  test 'update can change title and body' do
    sign_in users(:admin)
    note = notes(:admin_note_one)

    patch note_path(note), params: { note: { title: 'Updated Title', body: 'Updated Body' } }, as: :json
    assert_response :success

    note.reload
    assert_equal 'Updated Title', note.title
    assert_equal 'Updated Body', note.body
  end

  test 'destroy removes note' do
    sign_in users(:admin)
    note = notes(:admin_note_one)

    assert_difference('Note.count', -1) do
      delete note_path(note), as: :json
    end

    assert_response :no_content
  end

  test 'user can only see own notes' do
    sign_in users(:regular)
    get note_path(notes(:admin_note_one)), as: :json
    assert_response :not_found
  end
end
