# Supabase — Edge Functions

## `delete-account`

Permanently deletes the calling user's auth account. Apple App Review requires
apps that support account creation to also offer **in-app account deletion** —
this function is what the app calls when the user confirms deletion.

How it works:

1. The app invokes the function with the user's JWT (`Authorization: Bearer …`).
2. The function re-verifies the caller via `auth.getUser()` and only ever
   deletes **that** user — the client cannot pass a user id.
3. The auth user is removed with the Admin API. Every user table references
   `auth.users(id) ON DELETE CASCADE`, so `profiles`, `accounts`,
   `transactions`, `budgets`, and `categories` rows are all cascade-deleted.
   No manual table cleanup needed.

---

## Deploying

Requires the [Supabase CLI](https://supabase.com/docs/guides/cli).

```bash
supabase login
supabase link --project-ref odxzvfhxgsvqmgydlamm
supabase functions deploy delete-account
```

---

## Notes

- `SUPABASE_URL`, `SUPABASE_ANON_KEY`, and `SUPABASE_SERVICE_ROLE_KEY` are
  auto-injected by the Supabase Edge runtime — **no secrets live in this repo**.
- `verify_jwt` stays **enabled** (the default), so unauthenticated requests
  never reach the function. The function still re-verifies the caller with
  `auth.getUser()` before deleting, as defense in depth.
- Deletion is irreversible. The app must clear its local session afterwards;
  `AuthManager.deleteAccount()` handles both steps.
