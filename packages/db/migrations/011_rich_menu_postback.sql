-- Migration 011: Rich Menu Postback Responses
-- payload ごとに返信メッセージ JSON を管理するテーブル
CREATE TABLE IF NOT EXISTS rich_menu_postback_responses (
  payload    TEXT PRIMARY KEY,
  name       TEXT NOT NULL,
  body_json  TEXT NOT NULL,
  updated_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%f', 'now', '+9 hours'))
);
