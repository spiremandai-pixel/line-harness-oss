-- Migration 028: auto_replies テーブルに line_account_id カラムを追加
-- これにより message_received のオートメーションが正常に動作する

ALTER TABLE auto_replies ADD COLUMN line_account_id TEXT REFERENCES line_accounts(id) ON DELETE CASCADE;
