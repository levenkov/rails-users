class CreateOrderItemSplits < ActiveRecord::Migration[8.0]
  def change
    create_table :order_item_splits do |t|
      t.references :order_item, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.decimal :share, precision: 10, scale: 2, null: false

      t.timestamps
    end

    add_index :order_item_splits, %i[order_item_id user_id], unique: true
  end
end
