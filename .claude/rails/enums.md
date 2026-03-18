Use PostgreSQL enum types instead of string columns.

Define enum values in `lib/<model>_states.rb` to share between model and migration:

```ruby
module OrderStates
  ALL = %i[submitted approved delivery_waiting in_delivery finished].freeze
end
```

Model uses `simple_enum` + AASM:

```ruby
simple_enum :state, *OrderStates::ALL, default: :submitted

aasm column: :state, enum: false do
  state :submitted, initial: true
  # ...
end
```

Migration creates PostgreSQL enum type:

```ruby
require_relative '../../lib/order_states'

def up
  states = OrderStates::ALL
  execute "CREATE TYPE order_state AS ENUM (#{states.map { |s| "'#{s}'" }.join(', ')});"

  create_table :orders do |t|
    t.column :state, :order_state, null: false, default: 'submitted'
  end
end

def down
  drop_table :orders
  execute "DROP TYPE IF EXISTS order_state;"
end
```
