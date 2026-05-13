-- Migration 031: CV automationのactions JSONを修正
-- Flex Messageを廃止してシンプルなテキストメッセージに変更し、track_conversionも追加

-- 共通（予約完了）
UPDATE automations
SET actions    = '[{"type":"add_tag","params":{"tagId":"tag-cv-reserved"}},{"type":"send_message","params":{"messageType":"text","content":"✅ ご予約が完了しました\n\nご予約ありがとうございます！スタッフ一同、ご来店を心よりお待ちしております 🙌\n\n💡 予約完了ページの「LINEに通知」ボタンをタップいただいたことで、このメッセージが届いています。ご予約内容は予約システムにてご確認ください。"}},{"type":"track_conversion","params":{"conversionPointId":"cv-point-reserved"}}]',
    updated_at = datetime('now', '+9 hours')
WHERE id = 'auto-denba-cv-common';

-- 経堂店
UPDATE automations
SET actions    = '[{"type":"add_tag","params":{"tagId":"tag-cv-reserved"}},{"type":"add_tag","params":{"tagId":"tag-cv-reserved-kyodo"}},{"type":"send_message","params":{"messageType":"text","content":"✅ ご予約が完了しました（経堂店）\n\nご予約ありがとうございます！経堂店でのご来店をスタッフ一同お待ちしております 🙌\n\n💡 予約完了ページの「LINEに通知」ボタンをタップいただいたことで、このメッセージが届いています。ご予約内容は予約システムにてご確認ください。"}},{"type":"track_conversion","params":{"conversionPointId":"cv-point-reserved-kyodo"}}]',
    updated_at = datetime('now', '+9 hours')
WHERE id = 'auto-denba-cv-kyodo';

-- 浦和美園店
UPDATE automations
SET actions    = '[{"type":"add_tag","params":{"tagId":"tag-cv-reserved"}},{"type":"add_tag","params":{"tagId":"tag-cv-reserved-uraamisono"}},{"type":"send_message","params":{"messageType":"text","content":"✅ ご予約が完了しました（浦和美園店）\n\nご予約ありがとうございます！浦和美園店でのご来店をスタッフ一同お待ちしております 🙌\n\n💡 予約完了ページの「LINEに通知」ボタンをタップいただいたことで、このメッセージが届いています。ご予約内容は予約システムにてご確認ください。"}},{"type":"track_conversion","params":{"conversionPointId":"cv-point-reserved-uraamisono"}}]',
    updated_at = datetime('now', '+9 hours')
WHERE id = 'auto-denba-cv-uraamisono';
