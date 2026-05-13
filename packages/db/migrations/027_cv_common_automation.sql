-- Migration 027: 共通版「予約完了」キーワード対応オートメーション

INSERT OR IGNORE INTO automations
  (id, name, event_type, conditions, actions, is_active, line_account_id, created_at, updated_at)
VALUES (
  'auto-denba-cv-common',
  'CV計測 予約完了（共通）',
  'message_received',
  '{"keyword":"予約完了"}',
  '[{"type":"add_tag","params":{"tagId":"tag-cv-reserved"}},{"type":"send_message","params":{"messageType":"text","content":"ご予約ありがとうございます！\nスタッフ一同、ご来店を楽しみにしております 🙌\n\nご不明点はいつでもこちらからご連絡ください。"}}]',
  1,
  'dc316237-52ee-434e-bff1-addca7cde55e',
  datetime('now', '+9 hours'),
  datetime('now', '+9 hours')
);
