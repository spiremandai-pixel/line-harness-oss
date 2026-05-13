-- Migration 016: ステップ配信テーブル作成（step_messages / user_step_status）

CREATE TABLE IF NOT EXISTS step_messages (
  id            INTEGER PRIMARY KEY AUTOINCREMENT,
  day_offset    INTEGER NOT NULL UNIQUE,          -- 0/1/3/7/14
  send_hour_jst INTEGER NOT NULL DEFAULT 11,      -- 配信時刻（時・JST）
  body_json     TEXT    NOT NULL,                 -- {"messages":[...]} LINE Messaging API 配列
  is_active     INTEGER NOT NULL DEFAULT 1,
  created_at    TEXT    NOT NULL DEFAULT (datetime('now')),
  updated_at    TEXT    NOT NULL DEFAULT (datetime('now'))
);

CREATE TABLE IF NOT EXISTS user_step_status (
  line_user_id             TEXT    PRIMARY KEY,
  friend_added_at          TEXT    NOT NULL,       -- 友だち追加日時（起点・UTC）
  last_sent_day            INTEGER DEFAULT NULL,   -- 最後に送ったday_offset
  reservation_completed_at TEXT    DEFAULT NULL,   -- 予約完了で配信停止
  unsubscribed_at          TEXT    DEFAULT NULL,   -- ブロック・配信停止
  step_status              TEXT    NOT NULL DEFAULT 'active', -- active / completed / stopped
  created_at               TEXT    NOT NULL DEFAULT (datetime('now')),
  updated_at               TEXT    NOT NULL DEFAULT (datetime('now'))
);

CREATE INDEX IF NOT EXISTS idx_user_step_status_active
  ON user_step_status (step_status, friend_added_at)
  WHERE step_status = 'active';
