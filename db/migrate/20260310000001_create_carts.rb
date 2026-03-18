class CreateCarts < ActiveRecord::Migration[8.0]
  def change
    create_table :carts do |t|
      t.references :owner, null: false, foreign_key: { to_table: :users }
      t.references :market, null: false, foreign_key: true
      t.boolean :closed, null: false, default: false
      t.timestamps
    end

    create_table :cart_participants do |t|
      t.references :cart, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.boolean :ready, null: false, default: false
      t.timestamps
    end

    add_index :cart_participants, %i[cart_id user_id], unique: true

    add_foreign_key :orders, :carts
  end
end
