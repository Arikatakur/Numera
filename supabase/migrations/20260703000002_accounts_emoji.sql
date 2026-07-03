-- Migration: accounts_emoji
-- Purpose: Quanto-style accounts — emoji icon instead of SF Symbol, and a default
--          "Main account" created for every user so the app always has one to write to.

ALTER TABLE public.accounts
  ADD COLUMN emoji text NOT NULL DEFAULT '🏦';

-- Map the old SF Symbol names onto emoji for existing rows.
UPDATE public.accounts
SET emoji = CASE sf_symbol
  WHEN 'banknote'                 THEN '💵'
  WHEN 'building.columns'         THEN '🏦'
  WHEN 'creditcard'               THEN '💳'
  WHEN 'chart.line.uptrend.xyaxis' THEN '📈'
  ELSE '🏦'
END;

ALTER TABLE public.accounts DROP COLUMN sf_symbol;

-- Seed a default account on sign-up.
CREATE OR REPLACE FUNCTION public.seed_default_account()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER SET search_path = public
AS $$
BEGIN
  INSERT INTO public.accounts (user_id, name, balance, emoji)
  VALUES (new.id, 'Main account', 0, '🏦');
  RETURN new;
END;
$$;

CREATE OR REPLACE TRIGGER on_profile_created_seed_account
  AFTER INSERT ON public.profiles
  FOR EACH ROW EXECUTE PROCEDURE public.seed_default_account();

-- Backfill: give existing users with no accounts a default one.
INSERT INTO public.accounts (user_id, name, balance, emoji)
SELECT p.id, 'Main account', 0, '🏦'
FROM public.profiles p
WHERE NOT EXISTS (SELECT 1 FROM public.accounts a WHERE a.user_id = p.id);
