# Migrations

Each `.sql` file in this folder is a numbered migration that is applied exactly once.

## File naming convention

```
<version>_<description>.sql
```

Examples: `0001_create_app_schema.sql`, `0002_add_public_challenges.sql`

## Applying migrations

### Option A — `migrate.sh` (recommended)

Requires `psql` (`brew install postgresql` on macOS).

```bash
# 1. Set your database URL (find it in Supabase → Project Settings → Database → URI)
export DATABASE_URL="postgresql://postgres:<password>@db.<project-ref>.supabase.co:5432/postgres"

# 2. Run
./scripts/migrate.sh
```

The script:
- Creates a `schema_migrations` table on first run to track applied versions.
- Skips files whose version already exists in that table.
- Applies pending files in alphabetical (version) order.
- Is idempotent — safe to run multiple times.

You can also add `DATABASE_URL` to a `.env` file at the project root (add `.env` to `.gitignore`).

### Option B — Supabase SQL editor

1. Open your project in the [Supabase dashboard](https://app.supabase.com).
2. Go to **SQL Editor**.
3. Paste the contents of each pending migration file and run it.
4. Manually insert the version into `schema_migrations`:
   ```sql
   INSERT INTO schema_migrations (version, description)
   VALUES ('0002', '0002_add_public_challenges_and_schema_migrations.sql')
   ON CONFLICT DO NOTHING;
   ```

### Option C — Supabase CLI

If you have the [Supabase CLI](https://supabase.com/docs/guides/cli) installed:

```bash
supabase db push
```

> Note: The CLI expects migrations under `supabase/migrations/`. Copy files there if using this workflow.

## Migration history

| Version | Description |
|---------|-------------|
| 0001 | Create initial app schema (tasks, participants, invites, logs, RLS, functions) |
| 0002 | Public group challenges + schema_migrations tracking table |
