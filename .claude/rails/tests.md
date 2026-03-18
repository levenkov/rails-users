Minitest + fixtures. Mocha for mocking. Selenium with headless Chrome for system tests.

Run all: `bin/rails test` (excludes system tests).
Run system: `bin/rails test:system`.
Run single file: `bin/rails test test/models/user_test.rb`.
Run single test: `bin/rails test test/models/user_test.rb -n test_name`.

## Test types

- `test/models/` — model validations, state machines, business logic
- `test/controllers/` — request/response, auth, params, redirects
- `test/services/` — service object tests
- `test/system/` — full browser tests via Capybara + Selenium (headless Chrome)
- `test/mailers/` — email content and delivery
- `test/web/smoke/` — lightweight HTTP smoke tests for pages (check that page loads successfully)

## Fixtures

`test/fixtures/*.yml` — loaded globally via `fixtures :all`.

`test/fixtures/files/` — test file assets (images, etc.)

## Auth in tests

Controller/smoke tests use Devise helper: `sign_in users(:name)`.

System tests sign in through the browser form.
