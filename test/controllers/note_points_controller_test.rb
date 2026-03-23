require 'test_helper'

class NotePointsControllerTest < ActionDispatch::IntegrationTest
  test 'create adds point to note' do
    sign_in users(:admin)
    note = notes(:admin_note_one)

    assert_difference('NotePoint.count', 1) do
      post note_note_points_path(note), params: {
        note_point: { text: 'New point', position: 10 }
      }, as: :json
    end

    assert_response :created
    data = JSON.parse(response.body)
    assert_equal 'New point', data['text']
  end

  test 'create with parent_id creates nested point' do
    sign_in users(:admin)
    note = notes(:admin_note_one)
    parent = note_points(:point_one)

    assert_difference('NotePoint.count', 1) do
      post note_note_points_path(note), params: {
        note_point: { text: 'Nested point', position: 5, parent_id: parent.id }
      }, as: :json
    end

    assert_response :created
    data = JSON.parse(response.body)
    assert_equal parent.id, data['parent_id']
  end

  test 'update changes text' do
    sign_in users(:admin)
    note = notes(:admin_note_one)
    point = note_points(:point_one)

    patch note_note_point_path(note, point), params: {
      note_point: { text: 'Updated text' }
    }, as: :json

    assert_response :success
    point.reload
    assert_equal 'Updated text', point.text
  end

  test 'update toggles checked' do
    sign_in users(:admin)
    note = notes(:admin_note_one)
    point = note_points(:point_one)

    assert_not point.checked

    patch note_note_point_path(note, point), params: {
      note_point: { checked: true }
    }, as: :json

    assert_response :success
    point.reload
    assert point.checked
  end

  test 'destroy removes point' do
    sign_in users(:admin)
    note = notes(:admin_note_one)
    point = note_points(:point_two)

    assert_difference('NotePoint.count', -1) do
      delete note_note_point_path(note, point), as: :json
    end

    assert_response :no_content
  end
end
