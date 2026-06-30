-- Migration: create_transactions
-- Purpose: Core transaction records. Maps to Transaction.swift.
--
-- Swift model:
--   Transaction {
--     id: UUID, type: TransactionType, amount: Decimal,
--     category: Category, title: String, note: String?,
--     date: Date, accountName: String
--   }
--
-- Note: account_name stores the display name directly (matches current Swift model).
--       account_id is a nullable FK — wire it up when account management is added.

CREATE TABLE public.transactions (
  id           uuid                 NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id      uuid                 NOT NULL REFERENCES auth.users (id) ON DELETE CASCADE,
  type         transaction_type     NOT NULL,
  amount       numeric(14, 2)       NOT NULL CHECK (amount > 0),
  category     transaction_category NOT NULL,
  title        text                 NOT NULL,
  note         text,
  date         timestamptz          NOT NULL DEFAULT now(),
  account_name text                 NOT NULL DEFAULT 'Cash Account',
  account_id   uuid                 REFERENCES public.accounts (id) ON DELETE SET NULL,
  created_at   timestamptz          NOT NULL DEFAULT now(),
  updated_at   timestamptz          NOT NULL DEFAULT now()
);

-- Indexes for the most common query patterns.
CREATE INDEX transactions_user_id_idx        ON public.transactions (user_id);
CREATE INDEX transactions_user_date_idx      ON public.transactions (user_id, date DESC);
CREATE INDEX transactions_user_category_idx  ON public.transactions (user_id, category);
CREATE INDEX transactions_user_type_idx      ON public.transactions (user_id, type);

-- Auto-update updated_at.
CREATE OR REPLACE TRIGGER transactions_updated_at
  BEFORE UPDATE ON public.transactions
  FOR EACH ROW EXECUTE PROCEDURE public.set_updated_at();

-- RLS
ALTER TABLE public.transactions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can read own transactions"
  ON public.transactions FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own transactions"
  ON public.transactions FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own transactions"
  ON public.transactions FOR UPDATE
  USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own transactions"
  ON public.transactions FOR DELETE
  USING (auth.uid() = user_id);
