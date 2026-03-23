require 'test_helper'

class NormalizeNoteOrdersJobTest < ActiveSupport::TestCase
  test 'normalizes orders to multiples of 1000' do
    admin = users(:admin)
    notes(:admin_note_one).update_column(:order, 500)
    notes(:admin_note_two).update_column(:order, 1500)
    notes(:admin_note_three).update_column(:order, 7777)

    NormalizeNoteOrdersJob.perform_now

    orders = admin.notes.reorder(:order).pluck(:order)
    assert_equal [1000, 2000, 3000], orders
  end

  test 'handles multiple users independently' do
    NormalizeNoteOrdersJob.perform_now

    admin_orders = users(:admin).notes.reorder(:order).pluck(:order)
    regular_orders = users(:regular).notes.reorder(:order).pluck(:order)

    assert_equal [1000, 2000, 3000], admin_orders
    assert_equal [1000], regular_orders
  end

  test 'preserves relative order' do
    notes(:admin_note_one).update_column(:order, 100)
    notes(:admin_note_two).update_column(:order, 200)
    notes(:admin_note_three).update_column(:order, 300)

    NormalizeNoteOrdersJob.perform_now

    admin = users(:admin)
    ordered_notes = admin.notes.reorder(:order).to_a
    assert_equal notes(:admin_note_one).id, ordered_notes[0].id
    assert_equal notes(:admin_note_two).id, ordered_notes[1].id
    assert_equal notes(:admin_note_three).id, ordered_notes[2].id
  end

  test 'handles user with no notes' do
    user = User.create!(
      name: 'Empty User',
      email: "empty#{SecureRandom.hex(4)}@example.com",
      password: 'password123'
    )

    assert_nothing_raised do
      NormalizeNoteOrdersJob.perform_now
    end
  end
end
