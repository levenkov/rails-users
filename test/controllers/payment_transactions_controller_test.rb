require 'test_helper'

class PaymentTransactionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:regular)
    @admin = users(:admin)
    @order = orders(:submitted_order)
    sign_in @user
  end

  # -- create --

  test 'create payment transaction' do
    assert_difference('OrderPaymentTransaction.count') do
      post order_payment_transactions_path(@order), params: {
        order_payment_transaction: { amount: 250.00, comment: 'Bank transfer' }
      }
    end
    assert_redirected_to order_path(@order)

    payment = OrderPaymentTransaction.last
    assert_equal 250.00, payment.amount.to_f
    assert_equal 'Bank transfer', payment.comment
    assert_equal @user, payment.user
    assert_nil payment.confirmed_at
  end

  test 'create payment without comment' do
    assert_difference('OrderPaymentTransaction.count') do
      post order_payment_transactions_path(@order), params: {
        order_payment_transaction: { amount: 100.00 }
      }
    end
    assert_redirected_to order_path(@order)
  end

  test 'create payment fails with invalid amount' do
    assert_no_difference('OrderPaymentTransaction.count') do
      post order_payment_transactions_path(@order), params: {
        order_payment_transaction: { amount: 0 }
      }
    end
    assert_response :unprocessable_entity
  end

  test 'create payment requires authentication' do
    sign_out @user
    post order_payment_transactions_path(@order), params: {
      order_payment_transaction: { amount: 100.00 }
    }
    assert_response :redirect
  end

  # -- destroy --

  test 'author can revoke unconfirmed payment' do
    transaction = @order.order_payment_transactions.create!(user: @user, amount: 200.00)

    assert_difference('OrderPaymentTransaction.count', -1) do
      delete order_payment_transaction_path(@order, transaction)
    end
    assert_redirected_to order_path(@order)
    assert_equal 'Payment revoked.', flash[:notice]
  end

  test 'cannot revoke confirmed payment' do
    transaction = @order.order_payment_transactions.create!(
      user: @user, amount: 200.00, confirmed_at: Time.current
    )

    assert_no_difference('OrderPaymentTransaction.count') do
      delete order_payment_transaction_path(@order, transaction)
    end
    assert_redirected_to order_path(@order)
    assert_equal 'Cannot revoke a confirmed payment.', flash[:alert]
  end

  test 'non-author cannot revoke payment' do
    transaction = @order.order_payment_transactions.create!(user: @user, amount: 200.00)

    sign_in @admin
    assert_no_difference('OrderPaymentTransaction.count') do
      delete order_payment_transaction_path(@order, transaction)
    end
    assert_redirected_to order_path(@order)
    assert_equal 'Only the payment author can revoke.', flash[:alert]
  end

  test 'cannot revoke payment on archived order' do
    @order.update!(archived_at: Time.current)
    transaction = @order.order_payment_transactions.create!(user: @user, amount: 200.00)

    assert_no_difference('OrderPaymentTransaction.count') do
      delete order_payment_transaction_path(@order, transaction)
    end
    assert_redirected_to order_path(@order)
    assert_equal 'Cannot revoke payments on an archived order.', flash[:alert]
  end
end
