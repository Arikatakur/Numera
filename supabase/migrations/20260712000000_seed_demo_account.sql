-- Migration: seed_demo_account
-- Purpose: Populate a reviewer / App Review demo account with realistic,
--          date-relative data so every surface looks complete: Home, Activity
--          (all three transaction types — income, expense, transfer), all four
--          Insights ranges (Weekly / Monthly / Quarterly / Yearly) with both an
--          expense and an income category breakdown, Budget (overall +
--          per-category), Accounts, and the Pro Recurring & Budgeting insights.
--
-- Not seeded: Numera Pro entitlement. Premium is StoreKit-only and lives on the
--          device (PremiumManager), never in Postgres — App Review unlocks Pro
--          through the sandbox / StoreKit review environment, not this seed.
--
-- The demo account's email:
--          demo@clientvault.org
--
-- USAGE (run by hand in the Supabase SQL editor):
--   1. Create the auth user FIRST — Authentication → Users → Add user →
--      email = demo@clientvault.org, set a password, tick "Auto Confirm User"
--      (so email confirmation never blocks the App Review login).
--   2. Run this file. It looks the user up by email and seeds everything.
--   3. Re-run any time to reset the demo to "today" — it wipes and reseeds the
--      demo user's transactions + recurring rules against the current date, so
--      the Weekly tab (and Home "today") is never empty. Only the demo user is
--      touched; every other account is left alone.
--
-- If you pick a different demo address, change v_email below — nothing else.

DO $$
DECLARE
  v_email       text := 'demo@clientvault.org';
  v_user        uuid;
  v_ac_everyday uuid;
  v_ac_savings  uuid;
  v_ac_cash     uuid;
  -- category ids (resolved by name after the defaults are ensured)
  v_food uuid; v_coffee uuid; v_groceries uuid; v_transport uuid;
  v_shopping uuid; v_leisure uuid; v_health uuid; v_tech uuid;
  v_subs uuid; v_rent uuid; v_salary uuid; v_investments uuid;
  v_month_start timestamptz := date_trunc('month', now());
BEGIN
  SELECT id INTO v_user FROM auth.users WHERE email = v_email;
  IF v_user IS NULL THEN
    RAISE NOTICE 'Demo user % not found — create the auth account first, then re-run.', v_email;
    RETURN;
  END IF;

  -- Reviewer skips first-run onboarding and gets a friendly display name.
  UPDATE public.profiles
     SET has_completed_onboarding = true,
         display_name = COALESCE(display_name, 'Numera Demo')
   WHERE id = v_user;

  -- Categories: ensure the default set exists (normally seeded on sign-up),
  -- then add a custom "Rent" expense category for a realistic big line item.
  PERFORM public.seed_default_categories(v_user);

  INSERT INTO public.categories (user_id, name, emoji, color, kind, sort_order, is_default)
  SELECT v_user, 'Rent', '🏠', '#A5B4FC', 'expense', 11, false
  WHERE NOT EXISTS (
    SELECT 1 FROM public.categories WHERE user_id = v_user AND name = 'Rent'
  );

  SELECT id INTO v_food      FROM public.categories WHERE user_id = v_user AND name = 'Food'          LIMIT 1;
  SELECT id INTO v_coffee    FROM public.categories WHERE user_id = v_user AND name = 'Coffee'        LIMIT 1;
  SELECT id INTO v_groceries FROM public.categories WHERE user_id = v_user AND name = 'Groceries'     LIMIT 1;
  SELECT id INTO v_transport FROM public.categories WHERE user_id = v_user AND name = 'Transport'     LIMIT 1;
  SELECT id INTO v_shopping  FROM public.categories WHERE user_id = v_user AND name = 'Shopping'      LIMIT 1;
  SELECT id INTO v_leisure   FROM public.categories WHERE user_id = v_user AND name = 'Leisure'       LIMIT 1;
  SELECT id INTO v_health    FROM public.categories WHERE user_id = v_user AND name = 'Health'        LIMIT 1;
  SELECT id INTO v_tech      FROM public.categories WHERE user_id = v_user AND name = 'Tech'          LIMIT 1;
  SELECT id INTO v_subs      FROM public.categories WHERE user_id = v_user AND name = 'Subscriptions' LIMIT 1;
  SELECT id INTO v_rent      FROM public.categories WHERE user_id = v_user AND name = 'Rent'          LIMIT 1;
  SELECT id INTO v_salary    FROM public.categories WHERE user_id = v_user AND name = 'Salary'        LIMIT 1;
  SELECT id INTO v_investments FROM public.categories WHERE user_id = v_user AND name = 'Investments' LIMIT 1;

  -- Accounts: rename the seeded "Main account" → Everyday, add Savings + Cash.
  UPDATE public.accounts SET name = 'Everyday', emoji = '💳', balance = 5000
   WHERE user_id = v_user AND name = 'Main account';

  IF NOT EXISTS (SELECT 1 FROM public.accounts WHERE user_id = v_user AND name = 'Everyday') THEN
    INSERT INTO public.accounts (user_id, name, balance, emoji) VALUES (v_user, 'Everyday', 5000, '💳');
  END IF;
  IF NOT EXISTS (SELECT 1 FROM public.accounts WHERE user_id = v_user AND name = 'Savings') THEN
    INSERT INTO public.accounts (user_id, name, balance, emoji) VALUES (v_user, 'Savings', 20000, '🏦');
  END IF;
  IF NOT EXISTS (SELECT 1 FROM public.accounts WHERE user_id = v_user AND name = 'Cash') THEN
    INSERT INTO public.accounts (user_id, name, balance, emoji) VALUES (v_user, 'Cash', 600, '💵');
  END IF;

  SELECT id INTO v_ac_everyday FROM public.accounts WHERE user_id = v_user AND name = 'Everyday' LIMIT 1;
  SELECT id INTO v_ac_savings  FROM public.accounts WHERE user_id = v_user AND name = 'Savings'  LIMIT 1;
  SELECT id INTO v_ac_cash     FROM public.accounts WHERE user_id = v_user AND name = 'Cash'     LIMIT 1;

  -- Budgets: overall monthly limit + a few category limits (upsert).
  INSERT INTO public.budgets (user_id, category_id, amount, month_start) VALUES
    (v_user, NULL,        6000, NULL),
    (v_user, v_rent,      3300, NULL),
    (v_user, v_groceries, 700,  NULL),
    (v_user, v_food,      800,  NULL),
    (v_user, v_transport, 300,  NULL),
    (v_user, v_shopping,  500,  NULL)
  ON CONFLICT ON CONSTRAINT budgets_unique_user_category_month
  DO UPDATE SET amount = EXCLUDED.amount;

  -- Transactions: reset, then reseed relative to today.
  DELETE FROM public.transactions WHERE user_id = v_user;

  -- Monthly anchors for the last 12 months (income + fixed costs) so the
  -- Monthly / Quarterly / Yearly history charts all have bars.
  INSERT INTO public.transactions (user_id, type, amount, category_id, title, note, date, account_name, account_id)
  SELECT v_user, 'income', 12000, v_salary, 'Salary', 'Monthly pay',
         (v_month_start - make_interval(months => g.m)) + interval '9 hours',
         'Everyday', v_ac_everyday
  FROM generate_series(0, 11) AS g(m);

  INSERT INTO public.transactions (user_id, type, amount, category_id, title, note, date, account_name, account_id)
  SELECT v_user, 'expense', 3200, v_rent, 'Rent', 'Apartment rent',
         (v_month_start - make_interval(months => g.m)) + interval '1 day' + interval '10 hours',
         'Everyday', v_ac_everyday
  FROM generate_series(0, 11) AS g(m);

  INSERT INTO public.transactions (user_id, type, amount, category_id, title, note, date, account_name, account_id)
  SELECT v_user, 'expense', 55, v_subs, 'Netflix', 'Streaming',
         (v_month_start - make_interval(months => g.m)) + interval '4 days' + interval '8 hours',
         'Everyday', v_ac_everyday
  FROM generate_series(0, 11) AS g(m);

  INSERT INTO public.transactions (user_id, type, amount, category_id, title, note, date, account_name, account_id)
  SELECT v_user, 'expense', 380 + (g.m * 6), v_groceries, 'Groceries', 'Weekly shop',
         (v_month_start - make_interval(months => g.m)) + interval '13 days' + interval '18 hours',
         'Everyday', v_ac_everyday
  FROM generate_series(0, 11) AS g(m);

  -- Current-period scatter, including the last few days so the WEEKLY range and
  -- Home "today" are never empty regardless of when this is run.
  INSERT INTO public.transactions (user_id, type, amount, category_id, title, note, date, account_name, account_id) VALUES
    (v_user, 'expense', 18.00,  v_coffee,    'Morning coffee', NULL,         now() - interval '2 hours',  'Cash',     v_ac_cash),
    (v_user, 'expense', 64.50,  v_food,      'Lunch',          NULL,         now() - interval '5 hours',  'Everyday', v_ac_everyday),
    (v_user, 'expense', 32.00,  v_transport, 'Bus pass',       NULL,         now() - interval '1 day',    'Cash',     v_ac_cash),
    (v_user, 'expense', 128.90, v_groceries, 'Supermarket',    NULL,         now() - interval '1 day',    'Everyday', v_ac_everyday),
    (v_user, 'expense', 16.00,  v_coffee,    'Cortado',        NULL,         now() - interval '2 days',   'Cash',     v_ac_cash),
    (v_user, 'expense', 240.00, v_shopping,  'New shoes',      NULL,         now() - interval '2 days',   'Everyday', v_ac_everyday),
    (v_user, 'income',  800.00, v_salary,    'Bonus',          'Work bonus', now() - interval '3 days',   'Everyday', v_ac_everyday),
    (v_user, 'expense', 47.00,  v_leisure,   'Cinema',         NULL,         now() - interval '4 days',   'Everyday', v_ac_everyday),
    (v_user, 'expense', 88.00,  v_food,      'Dinner out',     NULL,         now() - interval '5 days',   'Everyday', v_ac_everyday),
    (v_user, 'expense', 60.00,  v_health,    'Pharmacy',       NULL,         now() - interval '7 days',   'Cash',     v_ac_cash),
    (v_user, 'expense', 320.00, v_tech,      'Headphones',     NULL,         now() - interval '9 days',   'Everyday', v_ac_everyday),
    (v_user, 'expense', 54.00,  v_food,      'Bakery',         NULL,         now() - interval '11 days',  'Everyday', v_ac_everyday),
    -- Second income category so the Insights income donut has more than one slice.
    (v_user, 'income',  300.00, v_investments, 'Dividends',    'Brokerage payout', now() - interval '6 days', 'Savings',  v_ac_savings),
    -- A transfer row exercises the third transaction type in Activity. Transfers
    -- carry no category and are excluded from balance/insights math by design.
    (v_user, 'transfer', 500.00, NULL,        'To Savings',     'Monthly top-up', now() - interval '3 days',  'Everyday', v_ac_everyday);

  -- Recurring rules: reset, then a realistic set with next_run in the near
  -- future (so the Recurring insight marks the current month and lists them).
  DELETE FROM public.recurring_rules WHERE user_id = v_user;
  INSERT INTO public.recurring_rules
    (user_id, type, amount, category_id, title, note, account_id, account_name, frequency, next_run, is_active) VALUES
    (v_user, 'expense', 3200,  v_rent,   'Rent',    'Apartment rent', v_ac_everyday, 'Everyday', 'monthly', v_month_start + interval '1 month 1 day',  true),
    (v_user, 'expense', 55,    v_subs,   'Netflix', 'Streaming',      v_ac_everyday, 'Everyday', 'monthly', v_month_start + interval '1 month 4 days', true),
    (v_user, 'expense', 40,    v_health, 'Gym',     'Weekly class',   v_ac_everyday, 'Everyday', 'weekly',  now() + interval '3 days',                 true),
    (v_user, 'income',  12000, v_salary, 'Salary',  'Monthly pay',    v_ac_everyday, 'Everyday', 'monthly', v_month_start + interval '1 month',        true);

  RAISE NOTICE 'Seeded demo account % (user %).', v_email, v_user;
END $$;
