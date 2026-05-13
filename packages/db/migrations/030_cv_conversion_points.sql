-- Migration 030: CVポイントを作成し、オートメーションと連携
-- CV計測ページにコンバージョンが表示されるようになる

-- ① CVポイント定義（共通・経堂・浦和美園）
INSERT OR IGNORE INTO conversion_points (id, name, event_type, created_at)
VALUES
  ('cv-point-reserved',            '予約完了（共通）',    'message_received', datetime('now', '+9 hours')),
  ('cv-point-reserved-kyodo',      '予約完了（経堂）',    'message_received', datetime('now', '+9 hours')),
  ('cv-point-reserved-uraamisono', '予約完了（浦和美園）', 'message_received', datetime('now', '+9 hours'));

-- ② オートメーションに track_conversion アクションを追加
--    （既存のactions JSON配列の末尾 ] の前に追記）

UPDATE automations
SET actions    = SUBSTR(actions, 1, LENGTH(actions) - 1) || ',{"type":"track_conversion","params":{"conversionPointId":"cv-point-reserved"}}]',
    updated_at = datetime('now', '+9 hours')
WHERE id = 'auto-denba-cv-common';

UPDATE automations
SET actions    = SUBSTR(actions, 1, LENGTH(actions) - 1) || ',{"type":"track_conversion","params":{"conversionPointId":"cv-point-reserved-kyodo"}}]',
    updated_at = datetime('now', '+9 hours')
WHERE id = 'auto-denba-cv-kyodo';

UPDATE automations
SET actions    = SUBSTR(actions, 1, LENGTH(actions) - 1) || ',{"type":"track_conversion","params":{"conversionPointId":"cv-point-reserved-uraamisono"}}]',
    updated_at = datetime('now', '+9 hours')
WHERE id = 'auto-denba-cv-uraamisono';
