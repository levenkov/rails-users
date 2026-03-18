require 'test_helper'

class FinancialTransactionTest < ActiveSupport::TestCase
  test 'valid financial transaction' do
    txn = financial_transactions(:payment_one)
    assert txn.valid?
  end

  test 'requires amount greater than 0' do
    txn = FinancialTransaction.new(sender: users(:regular), receiver: users(:admin), amount: 0)
    assert_not txn.valid?
    assert_includes txn.errors[:amount], 'must be greater than 0'
  end

  test 'belongs to sender and receiver' do
    txn = financial_transactions(:payment_one)
    assert_equal users(:regular), txn.sender
    assert_equal users(:admin), txn.receiver
  end
end
