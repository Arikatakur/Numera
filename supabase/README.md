# Supabase — Database Setup

## Migrations

Apply these in order via **Supabase Dashboard → SQL Editor → New query**.

| File | What it creates |
|---|---|
| `20260701000000_create_types.sql` | `transaction_type` and `transaction_category` Postgres enums |
| `20260701000001_create_profiles.sql` | `profiles` table + auto-create trigger on sign-up |
| `20260701000002_create_accounts.sql` | `accounts` table + RLS |
| `20260701000003_create_transactions.sql` | `transactions` table + RLS + indexes |
| `20260701000004_create_budgets.sql` | `budgets` table + RLS + $3,000 default seed |
| `20260703000000_create_categories.sql` | **Schema v2** — user-editable `categories` (emoji, color, kind, sort order) + default seed trigger + backfill |
| `20260703000001_rewire_category_refs.sql` | **Schema v2** — `transactions.category_id` / `budgets.category_id` FKs, drops the `transaction_category` enum |
| `20260703000002_accounts_emoji.sql` | **Schema v2** — `accounts.emoji` (replaces `sf_symbol`) + default "Main account" seed |
| `20260706000000_create_recurring_rules.sql` | **Numera Pro** — `recurring_rules` (recurring transaction templates) + RLS + due-index |

Run them one file at a time, top to bottom. Each depends on the previous.

> **Schema v2 note:** after `20260703000001`, the old `category` enum columns are
> gone. App builds older than the Quanto-redesign branch can no longer insert
> transactions — update the app together with the database.

---

## Schema v2 (current)

| Table | Key columns |
|---|---|
| `profiles` | `id` (= auth.users.id), `email`, `display_name`, `currency` |
| `categories` | `name`, `emoji`, `color` (hex), `kind` (`expense`/`income`), `sort_order`, `is_default` |
| `accounts` | `name`, `balance` (starting balance), `emoji` |
| `transactions` | `type`, `amount`, `category_id` → categories, `title`, `note`, `date`, `account_id` → accounts, `account_name` (denormalized fallback) |
| `budgets` | `category_id` (NULL = overall monthly budget), `amount`, `month_start` (NULL = repeats monthly) |

Legacy enum → category-name mapping used by the rewire migration (and CSV import):
`food→Food, coffee→Coffee, transport→Transport, groceries→Groceries, leisure→Leisure,
health→Health, shopping→Shopping, tech→Tech, travel→Travel, income→Salary,
investment→Investments, other→Other`.

---

## Row Level Security

Every table has RLS enabled. Users can only read, insert, update, and delete
their own rows (`auth.uid() = user_id`). No data leaks between accounts.

---

## What happens on sign-up

1. Supabase Auth creates a row in `auth.users`.
2. `on_auth_user_created` trigger → inserts a row in `profiles`.
3. `on_profile_created_seed_budget` trigger → default $3,000/month overall budget.
4. `on_profile_created_seed_categories` trigger → 11 expense + 4 income default categories.
5. `on_profile_created_seed_account` trigger → "Main account" with 0 balance.

---

## Notes

- `accounts.balance` is the **starting** balance; the app computes the current
  balance as `starting + income − expenses` over that account's transactions.
- `transactions.account_name` keeps the display name so history still renders
  if an account is deleted (`account_id` becomes NULL via `ON DELETE SET NULL`).
- Deleting a category sets `transactions.category_id` to NULL (rows render as
  "Other" in the app) and cascades its per-category budget rows.
- `budgets.category_id = NULL` means the overall monthly budget (used for
  safe-to-spend). `month_start = NULL` means the budget repeats every month.
