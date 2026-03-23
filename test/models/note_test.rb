require 'test_helper'

class NoteTest < ActiveSupport::TestCase
  test 'first note for a user gets order 1000' do
    user = User.create!(
      name: 'Test User',
      email: "notetest#{SecureRandom.hex(4)}@example.com",
      password: 'password123'
    )

    note = user.notes.create!(title: 'First note')
    assert_equal 1000, note.order
  end

  test 'subsequent notes get max order + 1000' do
    user = users(:admin)
    max_order = user.notes.unscoped.where(user_id: user.id).maximum(:order)

    note = user.notes.create!(title: 'New note')
    assert_equal max_order + 1000, note.order
  end

  test 'insert_between calculates midpoint correctly' do
    result = Note.insert_between(1000, 3000)
    assert_equal 2000, result
  end

  test 'insert_between with adjacent values returns lower value via integer division' do
    result = Note.insert_between(1000, 1001)
    assert_equal 1000, result
  end

  test 'default_scope orders by order field' do
    admin = users(:admin)
    notes = admin.notes.to_a
    orders = notes.map(&:order)
    assert_equal orders.sort, orders
  end

  test 'note belongs to user' do
    note = notes(:admin_note_one)
    assert_equal users(:admin), note.user
  end

  test 'note has many note_points' do
    note = notes(:admin_note_one)
    assert_includes note.note_points, note_points(:point_one)
    assert_includes note.note_points, note_points(:point_two)
  end

  test 'note has many note_tags through note_taggings' do
    note = notes(:admin_note_one)
    assert_includes note.note_tags, note_tags(:admin_tag_work)
  end

  test 'root_points returns only top-level points' do
    note = notes(:admin_note_one)
    roots = note.root_points
    assert_includes roots, note_points(:point_one)
    assert_includes roots, note_points(:point_two)
    assert_not_includes roots, note_points(:child_point)
  end
end
