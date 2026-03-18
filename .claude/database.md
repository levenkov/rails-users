# Database

- `users` - Accounts with roles (admin/regular)
- `user_oauths` - OAuth provider connections
- `markets` - User-owned marketplaces
- `articles` - Products within markets
- `orders` - Purchase orders with state machine (submitted → delivery_waiting → in_delivery → finished)
- `order_items` - Line items in orders
- `order_payments` - Payments for orders
- `financial_transactions` - Money transfers between users
- `active_storage_*` - File attachments

## Notes

- Admin role auto-assigned to user ID=1
- CORS enabled for all origins
- Development mode has intentional 1s delay in profile endpoint
