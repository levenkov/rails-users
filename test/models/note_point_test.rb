require 'test_helper'

class NotePointTest < ActiveSupport::TestCase
  test 'belongs to note' do
    point = note_points(:point_one)
    assert_equal notes(:admin_note_one), point.note
  end

  test 'belongs to parent optionally' do
    root_point = note_points(:point_one)
    assert_nil root_point.parent

    child = note_points(:child_point)
    assert_equal note_points(:point_one), child.parent
  end

  test 'has many children' do
    parent = note_points(:point_one)
    assert_includes parent.children, note_points(:child_point)
  end

  test 'requires text at database level' do
    assert_raises(ActiveRecord::NotNullViolation) do
      NotePoint.create!(note: notes(:admin_note_one), text: nil)
    end
  end

  test 'nested children are destroyed with parent' do
    parent = note_points(:point_one)
    child = note_points(:child_point)

    assert_difference('NotePoint.count', -2) do
      parent.destroy
    end

    assert_not NotePoint.exists?(child.id)
  end

  test 'default_scope orders by position' do
    note = notes(:admin_note_one)
    points = note.note_points.where(parent_id: nil).to_a
    positions = points.map(&:position)
    assert_equal positions.sort, positions
  end
end
