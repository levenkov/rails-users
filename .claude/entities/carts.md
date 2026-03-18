# Carts

Shared shopping carts. A user can own multiple carts. Any participant can manage the cart — there are no owner-only restrictions.

## Fields

| Column       | Type        | Default | Nullable | Notes                              |
|--------------|-------------|---------|----------|------------------------------------|
| `id`         | bigint      | auto    | no       | Primary key                        |
| `owner_id`   | bigint (FK) | —       | no       | Creator of the cart                |
| `market_id`  | bigint (FK) | —       | no       | All items must belong to this market |
| `created_at` | datetime    | now     | no       |                                    |
| `updated_at` | datetime    | now     | no       |                                    |

## Cart Participants

Tracks which users participate in a cart and their readiness status.

| Column       | Type        | Default | Nullable | Notes                          |
|--------------|-------------|---------|----------|--------------------------------|
| `id`         | bigint      | auto    | no       | Primary key                    |
| `cart_id`    | bigint (FK) | —       | no       | References `carts`             |
| `user_id`    | bigint (FK) | —       | no       | References `users`             |
| `ready`      | boolean     | `false` | no       | "I'm ready" flag               |
| `created_at` | datetime    | now     | no       |                                |
| `updated_at` | datetime    | now     | no       |                                |

Unique index on `[cart_id, user_id]`.

## Cart Items

Line items inside a cart. The same article variant can appear multiple times if added by different users — uniqueness is scoped to `[cart_id, article_variant_id, user_id]`.

| Column              | Type        | Default | Nullable | Notes                          |
|---------------------|-------------|---------|----------|--------------------------------|
| `id`                | bigint      | auto    | no       | Primary key                    |
| `cart_id`           | bigint (FK) | —       | no       | References `carts`             |
| `article_variant_id`| bigint (FK) | —       | no       | References `article_variants`  |
| `user_id`           | bigint (FK) | —       | no       | Who added this item            |
| `quantity`          | integer     | `1`     | no       | Must be > 0                    |
| `created_at`        | datetime    | now     | no       |                                |
| `updated_at`        | datetime    | now     | no       |                                |

## Associations

### Cart
- `belongs_to :owner, class_name: 'User'` — the creator
- `belongs_to :market` — restricts all items to one market
- `has_many :cart_participants` — participant records (dependent: destroy)
- `has_many :users, through: :cart_participants` — participant users
- `has_many :cart_items` — line items (dependent: destroy)

### User
- `has_many :my_carts, class_name: 'Cart', foreign_key: :owner_id` — carts the user owns

### CartParticipant
- `belongs_to :cart`
- `belongs_to :user`

### CartItem
- `belongs_to :cart`
- `belongs_to :article_variant`
- `belongs_to :user` — the participant who added the item

## Participants

Participants are tracked via the `cart_participants` table. Any participant can add/remove other participants and edit any items. Only the cart owner can destroy the cart and checkout. Each participant can toggle their `ready` flag to signal they're done adding items.

## Visibility

A user can see all carts where they appear in `cart_participants` (i.e. carts they own or participate in).

## Routes

RESTful plural routes: `resources :carts` with `index`, `show`, `update`, `destroy`. Collection actions: `add`, `remove`. Member actions: `add_participant`, `remove_participant`, `toggle_ready`.
