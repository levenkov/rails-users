require 'test_helper'

class OrderPaymentTransactionTest < ActiveSupport::TestCase
  test 'valid payment transaction' do
    payment = order_payment_transactions(:pending_payment)
    assert payment.valid?
  end

  test 'requires amount greater than 0' do
    payment = OrderPaymentTransaction.new(order: orders(:submitted_order), user: users(:regular), amount: 0)
    assert_not payment.valid?
    assert_includes payment.errors[:amount], 'must be greater than 0'
  end

  test 'belongs to order and user' do
    payment = order_payment_transactions(:pending_payment)
    assert_equal orders(:submitted_order), payment.order
    assert_equal users(:regular), payment.user
  end

  test 'confirmed? returns true when confirmed_at is set' do
    payment = order_payment_transactions(:confirmed_payment)
    assert payment.confirmed?
  end

  test 'confirmed? returns false when confirmed_at is nil' do
    payment = order_payment_transactions(:pending_payment)
    assert_not payment.confirmed?
  end

  test 'confirmed scope returns only confirmed payments' do
    confirmed = OrderPaymentTransaction.confirmed
    assert confirmed.all?(&:confirmed?)
  end

  test 'pending scope returns only unconfirmed payments' do
    pending = OrderPaymentTransaction.pending
    assert pending.none?(&:confirmed?)
  end

  test 'comment is optional' do
    payment = OrderPaymentTransaction.new(
      order: orders(:submitted_order),
      user: users(:regular),
      amount: 100.00
    )
    assert payment.valid?
  end
end
