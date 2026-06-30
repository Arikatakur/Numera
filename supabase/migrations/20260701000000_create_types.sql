-- Migration: create_types
-- Purpose: Enum types that map 1-to-1 with Swift enums in the app.

-- TransactionType enum
CREATE TYPE transaction_type AS ENUM (
  'expense',
  'income',
  'transfer'
);

-- Category enum (matches Category.rawValue in Transaction.swift)
CREATE TYPE transaction_category AS ENUM (
  'food',
  'coffee',
  'transport',
  'groceries',
  'leisure',
  'health',
  'shopping',
  'tech',
  'travel',
  'income',
  'investment',
  'other'
);
