-- Migration: create_accounts
-- Purpose: Financial accounts owned by a user. Maps to Account.swift.
--
-- Swift model:
--   Account { id: UUID, name: String, balance: Decimal, sfSymbol: String }

CREATE TABLE public.accounts (
  id          uuid        NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id     uuid        NOT NULL REFERENCES auth.users (id) ON DELETE CASCADE,
  name        text        NOT NULL,
  balance     numeric(14, 2) NOT NULL DEFAULT 0,
  sf_symbol   text        NOT NULL DEFAULT 'creditcard',
  created_at  timestamptz NOT NULL DEFAULT now(),
  updated_at  timestamptz NOT NULL DEFAULT now()
);

-- Index for fast per-user queries.
CREATE INDEX accounts_user_id_idx ON public.accounts (user_id);

-- Auto-update updated_at (reuses function from profiles migration).
CREATE OR REPLACE TRIGGER accounts_updated_at
  BEFORE UPDATE ON public.accounts
  FOR EACH ROW EXECUTE PROCEDURE public.set_updated_at();

-- RLS
ALTER TABLE public.accounts ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can read own accounts"
  ON public.accounts FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own accounts"
  ON public.accounts FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own accounts"
  ON public.accounts FOR UPDATE
  USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own accounts"
  ON public.accounts FOR DELETE
  USING (auth.uid() = user_id);
