-- Migration: create_budgets
-- Purpose: Monthly budget limits per category.
--          Powers the "safe to spend" calculation in HomeView and InsightsView.
--          Currently the app hardcodes $3,000/month — this replaces that.

CREATE TABLE public.budgets (
  id          uuid                  NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id     uuid                  NOT NULL REFERENCES auth.users (id) ON DELETE CASCADE,
  -- NULL category means the overall monthly budget (used for safe-to-spend).
  -- A specific category means a per-category limit.
  category    transaction_category,
  amount      numeric(14, 2)        NOT NULL CHECK (amount > 0),
  -- month_start is the first day of the month this budget applies to.
  -- Use '2026-07-01' for July 2026, etc.
  -- NULL means the budget repeats every month (default behaviour).
  month_start date,
  created_at  timestamptz           NOT NULL DEFAULT now(),
  updated_at  timestamptz           NOT NULL DEFAULT now(),

  -- One budget entry per user/category/month combination.
  CONSTRAINT budgets_unique_user_category_month
    UNIQUE NULLS NOT DISTINCT (user_id, category, month_start)
);

CREATE INDEX budgets_user_id_idx ON public.budgets (user_id);

CREATE OR REPLACE TRIGGER budgets_updated_at
  BEFORE UPDATE ON public.budgets
  FOR EACH ROW EXECUTE PROCEDURE public.set_updated_at();

-- RLS
ALTER TABLE public.budgets ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can read own budgets"
  ON public.budgets FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own budgets"
  ON public.budgets FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own budgets"
  ON public.budgets FOR UPDATE
  USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own budgets"
  ON public.budgets FOR DELETE
  USING (auth.uid() = user_id);

-- Seed the default overall monthly budget ($3,000) for every new user.
-- This mirrors the hardcoded value currently in TransactionStore.safeToSpend.
-- The trigger runs after a profile is inserted (i.e. on sign-up).
CREATE OR REPLACE FUNCTION public.seed_default_budget()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER SET search_path = public
AS $$
BEGIN
  INSERT INTO public.budgets (user_id, category, amount, month_start)
  VALUES (new.id, NULL, 3000, NULL);
  RETURN new;
END;
$$;

CREATE OR REPLACE TRIGGER on_profile_created_seed_budget
  AFTER INSERT ON public.profiles
  FOR EACH ROW EXECUTE PROCEDURE public.seed_default_budget();
