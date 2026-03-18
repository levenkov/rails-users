class CreateOrderPaymentTransactions < ActiveRecord::Migration[8.0]
  def change
    create_table :order_payment_transactions do |t|
      t.references :order, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.decimal :amount, precision: 10, scale: 2, null: false
      t.text :comment
      t.datetime :confirmed_at

      t.timestamps
    end
  end
end
