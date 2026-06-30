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

Run them one file at a time, top to bottom. Each depends on the previous.

---

## Swift enum → Postgres enum mapping

| Swift | Postgres column | Postgres type |
|---|---|---|
| `TransactionType.expense` | `type` | `'expense'` |
| `TransactionType.income` | `type` | `'income'` |
| `TransactionType.transfer` | `type` | `'transfer'` |
| `Category.food` | `category` | `'food'` |
| `Category.coffee` | `category` | `'coffee'` |
| `Category.transport` | `category` | `'transport'` |
| `Category.groceries` | `category` | `'groceries'` |
| `Category.leisure` | `category` | `'leisure'` |
| `Category.health` | `category` | `'health'` |
| `Category.shopping` | `category` | `'shopping'` |
| `Category.tech` | `category` | `'tech'` |
| `Category.travel` | `category` | `'travel'` |
| `Category.income` | `category` | `'income'` |
| `Category.investment` | `category` | `'investment'` |
| `Category.other` | `category` | `'other'` |

---

## Row Level Security

Every table has RLS enabled. Users can only read, insert, update, and delete
their own rows (`auth.uid() = user_id`). No data leaks between accounts.

---

## What happens on sign-up

1. Supabase Auth creates a row in `auth.users`.
2. `on_auth_user_created` trigger → inserts a row in `profiles`.
3. `on_profile_created_seed_budget` trigger → inserts a default $3,000/month
   overall budget in `budgets` for the new user.

---

## Notes

- `transactions.account_name` stores the display name as a string (matches the
  current Swift model). `transactions.account_id` is a nullable FK ready for
  when you wire up proper account management.
- `budgets.category = NULL` means the overall monthly budget (used for
  safe-to-spend). A non-null category means a per-category limit.
- `budgets.month_start = NULL` means the budget repeats every month.
