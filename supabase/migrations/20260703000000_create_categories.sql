-- Migration: create_categories
-- Purpose: User-editable categories (Quanto-style: emoji icon, color, expense/income kind,
--          manual sort order). Replaces the fixed transaction_category enum.
--
-- Swift model:
--   UserCategory { id: UUID, name: String, emoji: String, colorHex: String,
--                  kind: expense|income, sortOrder: Int, isDefault: Bool }

CREATE TABLE public.categories (
  id          uuid             NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id     uuid             NOT NULL REFERENCES auth.users (id) ON DELETE CASCADE,
  name        text             NOT NULL,
  emoji       text             NOT NULL DEFAULT '🧾',
  color       text             NOT NULL DEFAULT '#B8F36A',
  -- Reuses the transaction_type enum; only 'expense' and 'income' are valid for categories.
  kind        transaction_type NOT NULL DEFAULT 'expense' CHECK (kind IN ('expense', 'income')),
  sort_order  integer          NOT NULL DEFAULT 0,
  is_default  boolean          NOT NULL DEFAULT false,
  created_at  timestamptz      NOT NULL DEFAULT now(),
  updated_at  timestamptz      NOT NULL DEFAULT now()
);

CREATE INDEX categories_user_kind_sort_idx ON public.categories (user_id, kind, sort_order);

CREATE OR REPLACE TRIGGER categories_updated_at
  BEFORE UPDATE ON public.categories
  FOR EACH ROW EXECUTE PROCEDURE public.set_updated_at();

-- RLS
ALTER TABLE public.categories ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can read own categories"
  ON public.categories FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own categories"
  ON public.categories FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own categories"
  ON public.categories FOR UPDATE
  USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own categories"
  ON public.categories FOR DELETE
  USING (auth.uid() = user_id);

-- Default category set. Mirrors UserCategory.defaultExpense / .defaultIncome in Swift —
-- keep both sides in sync if you change names here (the FK-rewire migration and CSV import
-- match legacy values by these names).
CREATE OR REPLACE FUNCTION public.seed_default_categories(p_user uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER SET search_path = public
AS $$
BEGIN
  -- Idempotent: skip users who already have categories.
  IF EXISTS (SELECT 1 FROM public.categories WHERE user_id = p_user) THEN
    RETURN;
  END IF;

  INSERT INTO public.categories (user_id, name, emoji, color, kind, sort_order, is_default) VALUES
    (p_user, 'Food',          '🍽️', '#5DDBBD', 'expense', 0,  true),
    (p_user, 'Coffee',        '☕',  '#F8C46B', 'expense', 1,  true),
    (p_user, 'Groceries',     '🛒',  '#B8F36A', 'expense', 2,  true),
    (p_user, 'Transport',     '🚗',  '#6FB6FF', 'expense', 3,  true),
    (p_user, 'Shopping',      '🛍️', '#F472B6', 'expense', 4,  true),
    (p_user, 'Leisure',       '🍿',  '#A78BFA', 'expense', 5,  true),
    (p_user, 'Health',        '💊',  '#FF6B6B', 'expense', 6,  true),
    (p_user, 'Tech',          '💻',  '#FDBA74', 'expense', 7,  true),
    (p_user, 'Travel',        '✈️',  '#38BDF8', 'expense', 8,  true),
    (p_user, 'Subscriptions', '📅',  '#C4B5FD', 'expense', 9,  true),
    (p_user, 'Other',         '🧾',  '#9AA6B2', 'expense', 10, true),
    (p_user, 'Salary',        '💰',  '#B8F36A', 'income',  0,  true),
    (p_user, 'Investments',   '📈',  '#5DDBBD', 'income',  1,  true),
    (p_user, 'Gifts',         '🎁',  '#F472B6', 'income',  2,  true),
    (p_user, 'Other Income',  '🪙',  '#9AA6B2', 'income',  3,  true);
END;
$$;

-- Seed defaults for every new sign-up (runs alongside the profile/budget seed triggers).
CREATE OR REPLACE FUNCTION public.handle_new_user_categories()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER SET search_path = public
AS $$
BEGIN
  PERFORM public.seed_default_categories(new.id);
  RETURN new;
END;
$$;

CREATE OR REPLACE TRIGGER on_profile_created_seed_categories
  AFTER INSERT ON public.profiles
  FOR EACH ROW EXECUTE PROCEDURE public.handle_new_user_categories();

-- Backfill: seed defaults for all existing users.
SELECT public.seed_default_categories(id) FROM public.profiles;
