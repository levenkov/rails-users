# Project Context

## Business overview

This is a marketplace platform where users can create their own markets (stores), list articles
(products) within them, and process orders.

## Core entities

- **Users** — registered accounts with roles (admin/regular). Admin auto-assigned to user ID=1.
- **Markets** — user-owned marketplaces/stores.
- **Articles** — [products](entities/articles.md) listed within markets.
- **Orders** — [purchase orders](entities/orders.md) containing line items, payments, and financial transactions.

## Auth

Devise + JWT for API auth. OmniAuth with Google OAuth2 for social login.
