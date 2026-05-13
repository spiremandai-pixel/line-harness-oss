-- DENBAラウンジ 予約フォーム作成
INSERT OR IGNORE INTO forms (id, name, description, fields, on_submit_tag_id, save_to_metadata, is_active)
VALUES (
  'form-reservation',
  'DENBAラウンジ 体験予約フォーム',
  '初回体験ご予約のお申し込みフォームです',
  '[{"id":"store","label":"ご希望の店舗","type":"select","required":true,"options":["経堂店","浦和美園店"]},{"id":"preferred_date","label":"ご希望日時","type":"text","required":true,"placeholder":"例：5/15（木）13:00"},{"id":"name","label":"お名前","type":"text","required":true,"placeholder":"山田 太郎"},{"id":"phone","label":"お電話番号","type":"text","required":false,"placeholder":"090-xxxx-xxxx"},{"id":"note","label":"ご要望・備考","type":"textarea","required":false,"placeholder":"お気軽にご記入ください"}]',
  'tag-lc-reserved',
  1,
  1
);
