require 'test_helper'

class FinancialTransactionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:regular)
    @admin = users(:admin)
    sign_in @user
  end

  # -- index --

  test 'index returns success' do
    get financial_transactions_path
    assert_response :success
  end

  test 'index requires authentication' do
    sign_out @user
    get financial_transactions_path
    assert_redirected_to new_user_session_path
  end

  # -- new --

  test 'new returns success' do
    get new_financial_transaction_path
    assert_response :success
  end

  test 'new requires authentication' do
    sign_out @user
    get new_financial_transaction_path
    assert_redirected_to new_user_session_path
  end

  # -- create --

  test 'create financial transaction' do
    assert_difference('FinancialTransaction.count') do
      post financial_transactions_path, params: {
        financial_transaction: { receiver_id: @admin.id, amount: 500.00, description: 'Lunch money' }
      }
    end
    assert_redirected_to users_me_path

    ft = FinancialTransaction.last
    assert_equal @user, ft.sender
    assert_equal @admin, ft.receiver
    assert_equal 500.00, ft.amount.to_f
  end

  test 'create with invalid amount fails' do
    assert_no_difference('FinancialTransaction.count') do
      post financial_transactions_path, params: {
        financial_transaction: { receiver_id: @admin.id, amount: 0 }
      }
    end
    assert_response :unprocessable_entity
  end

  # -- edit --

  test 'edit own transaction returns success' do
    ft = FinancialTransaction.create!(sender: @user, receiver: @admin, amount: 100.00)
    get edit_financial_transaction_path(ft)
    assert_response :success
  end

  test 'cannot edit other users transaction' do
    ft = FinancialTransaction.create!(sender: @admin, receiver: @user, amount: 100.00)
    get edit_financial_transaction_path(ft)
    assert_response :not_found
  end

  # -- update --

  test 'update own transaction' do
    ft = FinancialTransaction.create!(sender: @user, receiver: @admin, amount: 100.00)
    patch financial_transaction_path(ft), params: {
      financial_transaction: { amount: 200.00, description: 'Updated' }
    }
    assert_redirected_to financial_transactions_path

    ft.reload
    assert_equal 200.00, ft.amount.to_f
    assert_equal 'Updated', ft.description
  end

  test 'update with invalid amount fails' do
    ft = FinancialTransaction.create!(sender: @user, receiver: @admin, amount: 100.00)
    patch financial_transaction_path(ft), params: {
      financial_transaction: { amount: 0 }
    }
    assert_response :unprocessable_entity
  end

  # -- destroy --

  test 'destroy own financial transaction' do
    ft = FinancialTransaction.create!(sender: @user, receiver: @admin, amount: 100.00)

    assert_difference('FinancialTransaction.count', -1) do
      delete financial_transaction_path(ft)
    end
  end

  test 'cannot destroy other users financial transaction' do
    ft = FinancialTransaction.create!(sender: @admin, receiver: @user, amount: 100.00)

    assert_no_difference('FinancialTransaction.count') do
      delete financial_transaction_path(ft)
    end
    assert_response :not_found
  end
end
