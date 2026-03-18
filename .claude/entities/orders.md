# Orders

Purchase orders containing line items, payments, and financial transactions.

## Fields

| Column         | Type                  | Default     | Nullable | Notes                        |
|----------------|-----------------------|-------------|----------|------------------------------|
| `id`           | bigint                | auto        | no       | Primary key                  |
| `state`        | enum (`order_state`)  | `submitted` | no       | See state machine below      |
| `sharing_type` | enum (`sharing_type`) | —           | yes      | `share`, `percent`, `amount` |
| `created_at`   | datetime              | now         | no       |                              |
| `updated_at`   | datetime              | now         | no       |                              |

## Associations

- `has_and_belongs_to_many :users` — order participants (join table `orders_users`)
- `has_many :order_items` — line items
- `has_many :order_item_splits` — through `order_items`
- `has_many :articles` — through `order_items`
- `has_many :order_payments`
- `has_many :split_approvals`

## State machine

`submitted` → `preparing` → `delivery_waiting` → `in_delivery` → `finished`

Split approval is tracked via `split_approvals` records — participants approve the splitting configuration, not the order itself.

## Splitting

Orders include order item splits with sharing types (share, percent, amount) for cost
distribution between participants.
