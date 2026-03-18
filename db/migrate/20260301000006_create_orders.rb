class CreateOrders < ActiveRecord::Migration[8.0]
  def up
    execute <<-SQL
      CREATE TYPE order_state AS ENUM (
        'submitted', 'preparing', 'delivery_waiting', 'in_delivery', 'finished'
      );
    SQL

    execute <<-SQL
      CREATE TYPE sharing_type AS ENUM ('share', 'percent', 'amount');
    SQL

    create_table :orders do |t|
      t.column :state, :order_state, null: false, default: 'submitted'
      t.column :sharing_type, :sharing_type
      t.references :cart, null: true
      t.references :owner, null: true, foreign_key: { to_table: :users }
      t.datetime :archived_at

      t.timestamps
    end

    add_index :orders, :state

    create_join_table :orders, :users do |t|
      t.index %i[order_id user_id], unique: true
      t.index :user_id
    end
  end

  def down
    drop_table :orders_users
    drop_table :orders

    execute "DROP TYPE order_state;"
    execute "DROP TYPE sharing_type;"
  end
end
