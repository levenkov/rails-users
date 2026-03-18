# Articles

Products listed within markets.

## Fields

| Column        | Type    | Default | Nullable | Notes                             |
|---------------|---------|---------|----------|-----------------------------------|
| `id`          | bigint  | auto    | no       | Primary key                       |
| `market_id`   | bigint (FK) | —   | no       | References `markets`              |
| `title`       | string  | —       | no       |                                   |
| `description` | text    | —       | yes      |                                   |
| `unlimited`   | boolean | `true`  | no       | See [Availability](#availability) |
| `stock`       | integer | `0`     | no       |                                   |
| `created_at`  | datetime | now    | no       |                                   |
| `updated_at`  | datetime | now    | no       |                                   |

## Article Variants

Each article has one or more variants (e.g. sizes M, L, XXL). Price lives on the variant.

| Column        | Type           | Default | Nullable | Notes              |
|---------------|----------------|---------|----------|--------------------|
| `id`          | bigint         | auto    | no       | Primary key        |
| `article_id`  | bigint (FK)    | —       | no       | References `articles` |
| `name`        | string         | —       | yes      | e.g. "M", "L", "XXL" |
| `price`       | decimal(10,2)  | —       | no       |                    |
| `created_at`  | datetime       | now     | no       |                    |
| `updated_at`  | datetime       | now     | no       |                    |

Single-variant articles have one variant with `name: nil`.

## Associations

- `belongs_to :market`
- `has_many :article_variants` — price variants (sizes, etc.)
- `has_many :order_items` — line items referencing this article
- `has_many :orders` — through `order_items`
- `has_many_attached :photos` — Active Storage attachments

## Availability

Controlled by the `unlimited` and `stock` fields:

- `unlimited=true` — article is always available, `stock` value is ignored
- `unlimited=false` — article is available only while `stock > 0`
