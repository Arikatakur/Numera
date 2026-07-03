-- Migration: rewire_category_refs
-- Purpose: Point transactions and budgets at the new categories table (uuid FK)
--          and remove the old transaction_category enum.
--
-- Legacy enum values are mapped to the seeded default categories by name:
--   food→Food, coffee→Coffee, transport→Transport, groceries→Groceries,
--   leisure→Leisure, health→Health, shopping→Shopping, tech→Tech, travel→Travel,
--   income→Salary, investment→Investments, other→Other
--
-- Requires: 20260703000000_create_categories (seeded categories for every user).

-- ── transactions ────────────────────────────────────────────────────────────

ALTER TABLE public.transactions
  ADD COLUMN category_id uuid REFERENCES public.categories (id) ON DELETE SET NULL;

UPDATE public.transactions t
SET category_id = c.id
FROM public.categories c
WHERE c.user_id = t.user_id
  AND c.name = CASE t.category::text
    WHEN 'food'       THEN 'Food'
    WHEN 'coffee'     THEN 'Coffee'
    WHEN 'transport'  THEN 'Transport'
    WHEN 'groceries'  THEN 'Groceries'
    WHEN 'leisure'    THEN 'Leisure'
    WHEN 'health'     THEN 'Health'
    WHEN 'shopping'   THEN 'Shopping'
    WHEN 'tech'       THEN 'Tech'
    WHEN 'travel'     THEN 'Travel'
    WHEN 'income'     THEN 'Salary'
    WHEN 'investment' THEN 'Investments'
    ELSE 'Other'
  END;

CREATE INDEX transactions_user_category_id_idx ON public.transactions (user_id, category_id);
DROP INDEX IF EXISTS public.transactions_user_category_idx;

ALTER TABLE public.transactions DROP COLUMN category;

-- ── budgets ─────────────────────────────────────────────────────────────────

ALTER TABLE public.budgets
  ADD COLUMN category_id uuid REFERENCES public.categories (id) ON DELETE CASCADE;

UPDATE public.budgets b
SET category_id = c.id
FROM public.categories c
WHERE b.category IS NOT NULL
  AND c.user_id = b.user_id
  AND c.name = CASE b.category::text
    WHEN 'food'       THEN 'Food'
    WHEN 'coffee'     THEN 'Coffee'
    WHEN 'transport'  THEN 'Transport'
    WHEN 'groceries'  THEN 'Groceries'
    WHEN 'leisure'    THEN 'Leisure'
    WHEN 'health'     THEN 'Health'
    WHEN 'shopping'   THEN 'Shopping'
    WHEN 'tech'       THEN 'Tech'
    WHEN 'travel'     THEN 'Travel'
    WHEN 'income'     THEN 'Salary'
    WHEN 'investment' THEN 'Investments'
    ELSE 'Other'
  END;

-- Rebuild the uniqueness rule around category_id (NULL category_id = overall budget).
ALTER TABLE public.budgets DROP CONSTRAINT budgets_unique_user_category_month;
ALTER TABLE public.budgets
  ADD CONSTRAINT budgets_unique_user_category_month
  UNIQUE NULLS NOT DISTINCT (user_id, category_id, month_start);

ALTER TABLE public.budgets DROP COLUMN category;

-- seed_default_budget referenced the dropped column list — recreate against category_id.
CREATE OR REPLACE FUNCTION public.seed_default_budget()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER SET search_path = public
AS $$
BEGIN
  INSERT INTO public.budgets (user_id, category_id, amount, month_start)
  VALUES (new.id, NULL, 3000, NULL);
  RETURN new;
END;
$$;

-- ── cleanup ─────────────────────────────────────────────────────────────────

-- No column references transaction_category anymore.
DROP TYPE public.transaction_category;
