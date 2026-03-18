# Claude instructions

Don't touch development DB.

We haven't deployed the project currently. So instead of creating new migrations for updating already existing entities,
update migrations.

Use `db:migrate:reset` instead of `db:drop db:create db:migrate`, read details in schema.md file.

Read another .claude/**.md files for specific cases.