-- Migration 018: entry_routes に line_account_id カラムを追加
ALTER TABLE entry_routes ADD COLUMN line_account_id TEXT REFERENCES line_accounts(id) ON DELETE CASCADE;

CREATE INDEX IF NOT EXISTS idx_entry_routes_account ON entry_routes (line_account_id);
