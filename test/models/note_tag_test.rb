require 'test_helper'

class NoteTagTest < ActiveSupport::TestCase
  test 'belongs to user' do
    tag = note_tags(:admin_tag_work)
    assert_equal users(:admin), tag.user
  end

  test 'validates name presence' do
    tag = NoteTag.new(user: users(:admin), name: nil)
    assert_not tag.valid?
    assert_includes tag.errors[:name], "can't be blank"
  end

  test 'validates name uniqueness scoped to user' do
    existing_tag = note_tags(:admin_tag_work)
    duplicate = NoteTag.new(user: existing_tag.user, name: existing_tag.name)
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:name], 'has already been taken'
  end

  test 'same name allowed for different users' do
    tag = NoteTag.new(user: users(:regular), name: 'work')
    assert tag.valid?
  end
end
