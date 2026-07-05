-- Migration: create_recurring_rules
-- Purpose: Recurring transaction templates (Numera Pro). Each active rule
-- auto-generates a transaction when due; the app advances next_run so
-- generation is idempotent across launches.

CREATE TABLE public.recurring_rules (
  id           uuid             NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id      uuid             NOT NULL REFERENCES auth.users (id) ON DELETE CASCADE,
  type         transaction_type NOT NULL,
  amount       numeric(14, 2)   NOT NULL CHECK (amount > 0),
  category_id  uuid             REFERENCES public.categories (id) ON DELETE SET NULL,
  title        text             NOT NULL,
  note         text,
  account_id   uuid             REFERENCES public.accounts (id) ON DELETE SET NULL,
  account_name text             NOT NULL DEFAULT '',
  frequency    text             NOT NULL CHECK (frequency IN ('weekly','monthly','yearly')),
  next_run     timestamptz      NOT NULL,
  is_active    boolean          NOT NULL DEFAULT true,
  created_at   timestamptz      NOT NULL DEFAULT now(),
  updated_at   timestamptz      NOT NULL DEFAULT now()
);

CREATE INDEX recurring_rules_user_idx ON public.recurring_rules (user_id);
CREATE INDEX recurring_rules_due_idx  ON public.recurring_rules (user_id, next_run) WHERE is_active;

-- Auto-update updated_at (shared trigger fn from the profiles migration).
CREATE OR REPLACE TRIGGER recurring_rules_updated_at
  BEFORE UPDATE ON public.recurring_rules
  FOR EACH ROW EXECUTE PROCEDURE public.set_updated_at();

-- RLS
ALTER TABLE public.recurring_rules ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can read own recurring rules"
  ON public.recurring_rules FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own recurring rules"
  ON public.recurring_rules FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own recurring rules"
  ON public.recurring_rules FOR UPDATE
  USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own recurring rules"
  ON public.recurring_rules FOR DELETE
  USING (auth.uid() = user_id);
