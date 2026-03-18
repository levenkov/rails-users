class CreateFinancialTransactions < ActiveRecord::Migration[8.0]
  def change
    create_table :financial_transactions do |t|
      t.references :sender, null: false, foreign_key: { to_table: :users }
      t.references :receiver, null: false, foreign_key: { to_table: :users }
      t.decimal :amount, precision: 10, scale: 2, null: false
      t.text :description

      t.timestamps
    end
  end
end
