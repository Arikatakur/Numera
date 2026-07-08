-- Migration: profile_onboarding
-- Purpose: Track first-run onboarding completion per user in the database, not
--          on-device. This way onboarding follows the account: a returning user
--          on a new device — or any existing account — skips it, while a
--          brand-new account sees it exactly once.

ALTER TABLE public.profiles
  ADD COLUMN has_completed_onboarding boolean NOT NULL DEFAULT false;

-- Existing users predate onboarding — don't force them back through it. New
-- sign-ups keep the column default (false) via handle_new_user(), so they are
-- onboarded on first launch.
UPDATE public.profiles SET has_completed_onboarding = true;

-- RLS: the existing "Users can read/update own profile" policies already cover
-- this column (they are row-level, all-columns), so the app can read the flag
-- and set it to true when onboarding finishes. No new policy needed.
