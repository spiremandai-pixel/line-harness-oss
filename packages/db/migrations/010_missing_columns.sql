-- Migration 010: Add missing line_account_id columns (partial 008 re-apply)
-- Migration 008 was only partially applied to production D1.
-- friends / messages_log / friend_scenarios already have line_account_id.
-- The following tables are still missing it.

ALTER TABLE broadcasts        ADD COLUMN line_account_id TEXT;
ALTER TABLE scenarios         ADD COLUMN line_account_id TEXT;
ALTER TABLE reminders         ADD COLUMN line_account_id TEXT;
ALTER TABLE automations       ADD COLUMN line_account_id TEXT;
ALTER TABLE chats             ADD COLUMN line_account_id TEXT;
ALTER TABLE notification_rules ADD COLUMN line_account_id TEXT;

-- line_accounts: add OAuth / LIFF columns from migration 008
ALTER TABLE line_accounts ADD COLUMN login_channel_id     TEXT;
ALTER TABLE line_accounts ADD COLUMN login_channel_secret TEXT;
ALTER TABLE line_accounts ADD COLUMN liff_id              TEXT;
