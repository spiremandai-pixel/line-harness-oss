-- Migration 023: DENBAラウンジ ウェルカムメッセージ自動化（案B）
-- 店舗選択クイックリプライボタン + タグ付け

-- ① store:undecided タグを追加
INSERT OR IGNORE INTO tags (id, name, color, created_at) VALUES
  ('tag-store-undecided', 'store:undecided', '#6B7280', datetime('now', '+9 hours'));

-- ② friend_add → クイックリプライ付きウェルカムメッセージ
INSERT OR IGNORE INTO automations
  (id, name, event_type, conditions, actions, is_active, line_account_id, created_at, updated_at)
VALUES (
  'auto-denba-welcome',
  'DENBAラウンジ ウェルカムメッセージ',
  'friend_add',
  '{}',
  '[{"type":"send_message","params":{"messageType":"raw","content":"{\"type\":\"text\",\"text\":\"友だち追加ありがとうございます！\\n\\nDENBAラウンジへようこそ。\\nお近くの店舗はどちらですか？\",\"quickReply\":{\"items\":[{\"type\":\"action\",\"action\":{\"type\":\"message\",\"label\":\"🏠 経堂店が近い\",\"text\":\"経堂店が近い\"}},{\"type\":\"action\",\"action\":{\"type\":\"message\",\"label\":\"🏠 浦和美園店が近い\",\"text\":\"浦和美園店が近い\"}},{\"type\":\"action\",\"action\":{\"type\":\"message\",\"label\":\"まだ決めていない\",\"text\":\"まだ決めていない\"}}]}}"}}]',
  1,
  'dc316237-52ee-434e-bff1-addca7cde55e',
  datetime('now', '+9 hours'),
  datetime('now', '+9 hours')
);

-- ③ message_received "経堂店が近い" → store:kyodo タグ付け
INSERT OR IGNORE INTO automations
  (id, name, event_type, conditions, actions, is_active, line_account_id, created_at, updated_at)
VALUES (
  'auto-denba-kyodo',
  'DENBAラウンジ 経堂店選択',
  'message_received',
  '{"keyword":"経堂店が近い"}',
  '[{"type":"add_tag","params":{"tagId":"tag-store-kyodo"}}]',
  1,
  'dc316237-52ee-434e-bff1-addca7cde55e',
  datetime('now', '+9 hours'),
  datetime('now', '+9 hours')
);

-- ④ message_received "浦和美園店が近い" → store:uraamisono タグ付け
INSERT OR IGNORE INTO automations
  (id, name, event_type, conditions, actions, is_active, line_account_id, created_at, updated_at)
VALUES (
  'auto-denba-uraamisono',
  'DENBAラウンジ 浦和美園店選択',
  'message_received',
  '{"keyword":"浦和美園店が近い"}',
  '[{"type":"add_tag","params":{"tagId":"tag-store-uraamisono"}}]',
  1,
  'dc316237-52ee-434e-bff1-addca7cde55e',
  datetime('now', '+9 hours'),
  datetime('now', '+9 hours')
);

-- ⑤ message_received "まだ決めていない" → store:undecided タグ付け
INSERT OR IGNORE INTO automations
  (id, name, event_type, conditions, actions, is_active, line_account_id, created_at, updated_at)
VALUES (
  'auto-denba-undecided',
  'DENBAラウンジ 店舗未決定',
  'message_received',
  '{"keyword":"まだ決めていない"}',
  '[{"type":"add_tag","params":{"tagId":"tag-store-undecided"}}]',
  1,
  'dc316237-52ee-434e-bff1-addca7cde55e',
  datetime('now', '+9 hours'),
  datetime('now', '+9 hours')
);
