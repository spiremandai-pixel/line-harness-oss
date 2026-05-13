-- Migration 026: CV計測をキーワード方式に変更
-- 電話番号収集を廃止し、サンクスページの「予約完了」メッセージで計測

-- ① 店舗選択オートメーションから電話番号リクエストを削除（タグ付けのみに戻す）
UPDATE automations
SET actions    = '[{"type":"add_tag","params":{"tagId":"tag-store-kyodo"}}]',
    updated_at = datetime('now', '+9 hours')
WHERE id = 'auto-denba-kyodo';

UPDATE automations
SET actions    = '[{"type":"add_tag","params":{"tagId":"tag-store-uraamisono"}}]',
    updated_at = datetime('now', '+9 hours')
WHERE id = 'auto-denba-uraamisono';

UPDATE automations
SET actions    = '[{"type":"add_tag","params":{"tagId":"tag-store-undecided"}}]',
    updated_at = datetime('now', '+9 hours')
WHERE id = 'auto-denba-undecided';

-- ② CV計測オートメーション: 「予約完了 経堂」を受信 → cv:reserved + cv:reserved_kyodo タグ + 確認メッセージ
INSERT OR IGNORE INTO automations
  (id, name, event_type, conditions, actions, is_active, line_account_id, created_at, updated_at)
VALUES (
  'auto-denba-cv-kyodo',
  'CV計測 経堂予約完了',
  'message_received',
  '{"keyword":"予約完了 経堂"}',
  '[{"type":"add_tag","params":{"tagId":"tag-cv-reserved"}},{"type":"add_tag","params":{"tagId":"tag-cv-reserved-kyodo"}},{"type":"send_message","params":{"messageType":"text","content":"ご予約ありがとうございます！\n経堂店でのご来店を楽しみにしております 🙌\n\nご不明点はいつでもこちらからご連絡ください。"}}]',
  1,
  'dc316237-52ee-434e-bff1-addca7cde55e',
  datetime('now', '+9 hours'),
  datetime('now', '+9 hours')
);

-- ③ CV計測オートメーション: 「予約完了 浦和美園」を受信 → cv:reserved + cv:reserved_uraamisono タグ + 確認メッセージ
INSERT OR IGNORE INTO automations
  (id, name, event_type, conditions, actions, is_active, line_account_id, created_at, updated_at)
VALUES (
  'auto-denba-cv-uraamisono',
  'CV計測 浦和美園予約完了',
  'message_received',
  '{"keyword":"予約完了 浦和美園"}',
  '[{"type":"add_tag","params":{"tagId":"tag-cv-reserved"}},{"type":"add_tag","params":{"tagId":"tag-cv-reserved-uraamisono"}},{"type":"send_message","params":{"messageType":"text","content":"ご予約ありがとうございます！\n浦和美園店でのご来店を楽しみにしております 🙌\n\nご不明点はいつでもこちらからご連絡ください。"}}]',
  1,
  'dc316237-52ee-434e-bff1-addca7cde55e',
  datetime('now', '+9 hours'),
  datetime('now', '+9 hours')
);
