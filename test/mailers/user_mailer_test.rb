require 'test_helper'

class UserMailerTest < ActionMailer::TestCase
  test 'password_changed' do
    admin_user = users(:admin)
    regular_user = users(:regular)

    email = UserMailer.with(user: regular_user, changed_by: admin_user).password_changed

    assert_emails 1 do
      email.deliver_now
    end

    assert_equal [ 'from@example.com' ], email.from
    assert_equal [ regular_user.email ], email.to
    assert_equal 'Your password has been changed', email.subject
    assert_match regular_user.name, email.body.encoded
    assert_match 'by an administrator', email.body.encoded
  end
end
