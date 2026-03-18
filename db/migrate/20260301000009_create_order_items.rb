class CreateOrderItems < ActiveRecord::Migration[8.0]
  def change
    create_table :order_items do |t|
      t.references :order, null: false, foreign_key: true
      t.references :article, null: false, foreign_key: true
      t.references :article_variant, foreign_key: true
      t.references :added_by_user, null: true, foreign_key: { to_table: :users }
      t.integer :quantity, default: 1
      t.decimal :price, precision: 10, scale: 2, null: false

      t.timestamps
    end
  end
end
