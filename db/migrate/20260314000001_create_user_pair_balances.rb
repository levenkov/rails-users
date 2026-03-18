class CreateUserPairBalances < ActiveRecord::Migration[8.0]
  def change
    create_table :user_pair_balances do |t|
      t.references :order, null: false, foreign_key: true
      t.references :user_low, null: false, foreign_key: { to_table: :users }
      t.references :user_high, null: false, foreign_key: { to_table: :users }
      t.decimal :balance, precision: 10, scale: 2, null: false

      t.timestamps
    end

    add_index :user_pair_balances, %i[order_id user_low_id user_high_id], unique: true,
      name: 'idx_user_pair_balances_unique'
  end
end
