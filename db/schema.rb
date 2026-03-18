# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 2026_03_14_000001) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  # Custom types defined in this database.
  # Note that some types may not work with other database engines. Be careful if changing database.
  create_enum "order_state", ["submitted", "preparing", "delivery_waiting", "in_delivery", "finished"]
  create_enum "sharing_type", ["share", "percent", "amount"]

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.string "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "article_variants", force: :cascade do |t|
    t.bigint "article_id", null: false
    t.string "name"
    t.decimal "price", precision: 10, scale: 2, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["article_id"], name: "index_article_variants_on_article_id"
  end

  create_table "articles", force: :cascade do |t|
    t.bigint "market_id", null: false
    t.string "title", null: false
    t.text "description"
    t.boolean "unlimited", default: true, null: false
    t.integer "stock", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["market_id"], name: "index_articles_on_market_id"
  end

  create_table "cart_items", force: :cascade do |t|
    t.bigint "cart_id", null: false
    t.bigint "article_variant_id", null: false
    t.bigint "user_id", null: false
    t.integer "quantity", default: 1, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["article_variant_id"], name: "index_cart_items_on_article_variant_id"
    t.index ["cart_id", "article_variant_id", "user_id"], name: "index_cart_items_on_cart_id_and_article_variant_id_and_user_id", unique: true
    t.index ["cart_id"], name: "index_cart_items_on_cart_id"
    t.index ["user_id"], name: "index_cart_items_on_user_id"
  end

  create_table "cart_participants", force: :cascade do |t|
    t.bigint "cart_id", null: false
    t.bigint "user_id", null: false
    t.boolean "ready", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["cart_id", "user_id"], name: "index_cart_participants_on_cart_id_and_user_id", unique: true
    t.index ["cart_id"], name: "index_cart_participants_on_cart_id"
    t.index ["user_id"], name: "index_cart_participants_on_user_id"
  end

  create_table "carts", force: :cascade do |t|
    t.bigint "owner_id", null: false
    t.bigint "market_id", null: false
    t.boolean "closed", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["market_id"], name: "index_carts_on_market_id"
    t.index ["owner_id"], name: "index_carts_on_owner_id"
  end

  create_table "financial_transactions", force: :cascade do |t|
    t.bigint "sender_id", null: false
    t.bigint "receiver_id", null: false
    t.decimal "amount", precision: 10, scale: 2, null: false
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["receiver_id"], name: "index_financial_transactions_on_receiver_id"
    t.index ["sender_id"], name: "index_financial_transactions_on_sender_id"
  end

  create_table "markets", force: :cascade do |t|
    t.bigint "owner_id", null: false
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["owner_id"], name: "index_markets_on_owner_id"
  end

  create_table "order_item_splits", force: :cascade do |t|
    t.bigint "order_item_id", null: false
    t.bigint "user_id", null: false
    t.decimal "share", precision: 10, scale: 2, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["order_item_id", "user_id"], name: "index_order_item_splits_on_order_item_id_and_user_id", unique: true
    t.index ["order_item_id"], name: "index_order_item_splits_on_order_item_id"
    t.index ["user_id"], name: "index_order_item_splits_on_user_id"
  end

  create_table "order_items", force: :cascade do |t|
    t.bigint "order_id", null: false
    t.bigint "article_id", null: false
    t.bigint "article_variant_id"
    t.bigint "added_by_user_id"
    t.integer "quantity", default: 1
    t.decimal "price", precision: 10, scale: 2, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["added_by_user_id"], name: "index_order_items_on_added_by_user_id"
    t.index ["article_id"], name: "index_order_items_on_article_id"
    t.index ["article_variant_id"], name: "index_order_items_on_article_variant_id"
    t.index ["order_id"], name: "index_order_items_on_order_id"
  end

  create_table "order_payment_transactions", force: :cascade do |t|
    t.bigint "order_id", null: false
    t.bigint "user_id", null: false
    t.decimal "amount", precision: 10, scale: 2, null: false
    t.text "comment"
    t.datetime "confirmed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["order_id"], name: "index_order_payment_transactions_on_order_id"
    t.index ["user_id"], name: "index_order_payment_transactions_on_user_id"
  end

  create_table "orders", force: :cascade do |t|
    t.enum "state", default: "submitted", null: false, enum_type: "order_state"
    t.enum "sharing_type", enum_type: "sharing_type"
    t.bigint "cart_id"
    t.bigint "owner_id"
    t.datetime "archived_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["cart_id"], name: "index_orders_on_cart_id"
    t.index ["owner_id"], name: "index_orders_on_owner_id"
    t.index ["state"], name: "index_orders_on_state"
  end

  create_table "orders_users", id: false, force: :cascade do |t|
    t.bigint "order_id", null: false
    t.bigint "user_id", null: false
    t.index ["order_id", "user_id"], name: "index_orders_users_on_order_id_and_user_id", unique: true
    t.index ["user_id"], name: "index_orders_users_on_user_id"
  end

  create_table "split_approvals", force: :cascade do |t|
    t.bigint "order_id", null: false
    t.bigint "user_id", null: false
    t.datetime "approved_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["order_id", "user_id"], name: "index_split_approvals_on_order_id_and_user_id", unique: true
    t.index ["order_id"], name: "index_split_approvals_on_order_id"
    t.index ["user_id"], name: "index_split_approvals_on_user_id"
  end

  create_table "user_oauths", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "provider", null: false
    t.string "uid", null: false
    t.string "email"
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["provider", "uid"], name: "index_user_oauths_on_provider_and_uid", unique: true
    t.index ["user_id", "provider"], name: "index_user_oauths_on_user_id_and_provider", unique: true
    t.index ["user_id"], name: "index_user_oauths_on_user_id"
  end

  create_table "user_pair_balances", force: :cascade do |t|
    t.bigint "order_id", null: false
    t.bigint "user_low_id", null: false
    t.bigint "user_high_id", null: false
    t.decimal "balance", precision: 10, scale: 2, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["order_id", "user_low_id", "user_high_id"], name: "idx_user_pair_balances_unique", unique: true
    t.index ["order_id"], name: "index_user_pair_balances_on_order_id"
    t.index ["user_high_id"], name: "index_user_pair_balances_on_user_high_id"
    t.index ["user_low_id"], name: "index_user_pair_balances_on_user_low_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "name", null: false
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.boolean "disabled", default: false, null: false
    t.string "role", default: "regular", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "article_variants", "articles"
  add_foreign_key "articles", "markets"
  add_foreign_key "cart_items", "article_variants"
  add_foreign_key "cart_items", "carts"
  add_foreign_key "cart_items", "users"
  add_foreign_key "cart_participants", "carts"
  add_foreign_key "cart_participants", "users"
  add_foreign_key "carts", "markets"
  add_foreign_key "carts", "users", column: "owner_id"
  add_foreign_key "financial_transactions", "users", column: "receiver_id"
  add_foreign_key "financial_transactions", "users", column: "sender_id"
  add_foreign_key "markets", "users", column: "owner_id"
  add_foreign_key "order_item_splits", "order_items"
  add_foreign_key "order_item_splits", "users"
  add_foreign_key "order_items", "article_variants"
  add_foreign_key "order_items", "articles"
  add_foreign_key "order_items", "orders"
  add_foreign_key "order_items", "users", column: "added_by_user_id"
  add_foreign_key "order_payment_transactions", "orders"
  add_foreign_key "order_payment_transactions", "users"
  add_foreign_key "orders", "carts"
  add_foreign_key "orders", "users", column: "owner_id"
  add_foreign_key "split_approvals", "orders"
  add_foreign_key "split_approvals", "users"
  add_foreign_key "user_oauths", "users"
  add_foreign_key "user_pair_balances", "orders"
  add_foreign_key "user_pair_balances", "users", column: "user_high_id"
  add_foreign_key "user_pair_balances", "users", column: "user_low_id"
end
