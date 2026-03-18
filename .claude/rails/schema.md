The default `schema.rb` cannot represent custom PostgreSQL types - they get converted to `varchar`.

Solution: we always rely on migrations as the source of truth.

In Rails 8, `db:migrate` may load schema instead of running migrations.

Use `db:migrate:reset` instead of `db:drop db:create db:migrate`
