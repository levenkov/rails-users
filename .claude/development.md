# Development Commands

```bash
# Start PostgreSQL + Redis
docker compose up -d

# Install dependencies
bin/bundle install && npm install

# Database setup
bin/rails db:migrate:reset

# Run dev server (Rails + Webpack)
bin/dev

# Or separately:
bin/rails server
npm run build -- --watch
```
