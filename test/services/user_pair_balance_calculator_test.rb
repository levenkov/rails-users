require 'test_helper'

class UserPairBalanceCalculatorTest < ActiveSupport::TestCase
  setup do
    @user = users(:regular)
    @admin = users(:admin)
    @order = orders(:finished_order)
    FinancialTransaction.delete_all

    # Create order items for the finished order
    @item = @order.order_items.create!(
      article: articles(:laptop),
      article_variant: article_variants(:laptop_default),
      quantity: 1,
      price: 1000.00
    )
  end

  test 'returns zero when no shared orders or transactions' do
    # Clean all items from finished order
    @order.order_items.destroy_all

    balance = UserPairBalanceCalculator.new(@user, @admin).call
    assert_equal BigDecimal('0'), balance
  end

  test 'calculates debt from order splits' do
    @order.update!(sharing_type: 'share')
    @item.order_item_splits.create!(user: @user, share: 1)
    @item.order_item_splits.create!(user: @admin, share: 1)

    # User pays full amount
    @order.order_payment_transactions.create!(user: @user, amount: 1000.00, confirmed_at: Time.current)

    balance = UserPairBalanceCalculator.new(@user, @admin).call

    low_id, _high_id = [ @user.id, @admin.id ].sort
    # positive = high owes low
    # admin owes regular 500
    if @user.id == low_id
      assert_in_delta 500.0, balance.to_f, 0.01  # high (admin) owes low (regular)
    else
      assert_in_delta(-500.0, balance.to_f, 0.01)
    end
  end

  test 'includes p2p financial transactions' do
    @order.order_items.destroy_all

    # Admin sends 200 to regular — settling debt admin owes regular
    FinancialTransaction.create!(sender: @admin, receiver: @user, amount: 200.00)

    balance = UserPairBalanceCalculator.new(@user, @admin).call

    low_id, _high_id = [ @user.id, @admin.id ].sort
    if @admin.id == low_id
      # sender is low (admin), receiver is high (regular)
      # low pays high → balance increases (high owes low more)
      assert_in_delta 200.0, balance.to_f, 0.01
    else
      # sender is high (admin), receiver is low (regular)
      # high pays low → balance decreases
      assert_in_delta(-200.0, balance.to_f, 0.01)
    end
  end

  test 'uses snapshot as starting point' do
    low_id, high_id = [ @user.id, @admin.id ].sort

    # Create a snapshot with balance 300
    UserPairBalance.create!(
      order: @order,
      user_low_id: low_id,
      user_high_id: high_id,
      balance: 300.00
    )
    @order.update!(archived_at: Time.current)

    # No new orders or transactions after snapshot
    balance = UserPairBalanceCalculator.new(@user, @admin).call
    assert_in_delta 300.0, balance.to_f, 0.01
  end
end
