-- Migration 025: 電話番号収集・CV照合用タグ + 店舗選択自動化に電話番号リクエストを追加

-- ① has:phone タグ（電話番号登録済みフレンド識別用）
INSERT OR IGNORE INTO tags (id, name, color, created_at) VALUES
  ('tag-has-phone', 'has:phone', '#8B5CF6', datetime('now', '+9 hours'));

-- ② 店舗選択オートメーション: 経堂 → 電話番号リクエストを追加
UPDATE automations
SET actions = '[{"type":"add_tag","params":{"tagId":"tag-store-kyodo"}},{"type":"send_message","params":{"messageType":"text","content":"ありがとうございます！経堂店ですね。\n\nご予約の照合のため、お電話番号をこちらに返信いただけますか？\n（例：090-1234-5678）\n\n登録いただくと、ご予約完了時にお知らせが届きます。"}}]',
    updated_at = datetime('now', '+9 hours')
WHERE id = 'auto-denba-kyodo';

-- ③ 店舗選択オートメーション: 浦和美園 → 電話番号リクエストを追加
UPDATE automations
SET actions = '[{"type":"add_tag","params":{"tagId":"tag-store-uraamisono"}},{"type":"send_message","params":{"messageType":"text","content":"ありがとうございます！浦和美園店ですね。\n\nご予約の照合のため、お電話番号をこちらに返信いただけますか？\n（例：090-1234-5678）\n\n登録いただくと、ご予約完了時にお知らせが届きます。"}}]',
    updated_at = datetime('now', '+9 hours')
WHERE id = 'auto-denba-uraamisono';

-- ④ 店舗選択オートメーション: 未決定 → 電話番号リクエストを追加
UPDATE automations
SET actions = '[{"type":"add_tag","params":{"tagId":"tag-store-undecided"}},{"type":"send_message","params":{"messageType":"text","content":"わかりました！店舗が決まりましたらまた教えてください。\n\nご予約の照合のため、お電話番号をこちらに返信いただけますか？\n（例：090-1234-5678）\n\n登録いただくと、ご予約完了時にお知らせが届きます。"}}]',
    updated_at = datetime('now', '+9 hours')
WHERE id = 'auto-denba-undecided';
