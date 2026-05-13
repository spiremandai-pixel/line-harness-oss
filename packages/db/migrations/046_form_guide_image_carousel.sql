-- Migration 015: store_select_carousel をフォームガイド画像 + 店舗カルーセルの2メッセージ構成に更新
UPDATE rich_menu_postback_responses
SET
  body_json = '{"messages":[{"type":"image","originalContentUrl":"https://pub-8dd04c3f08434d8a9435eea45c1a3992.r2.dev/form_guide/main.jpg","previewImageUrl":"https://pub-8dd04c3f08434d8a9435eea45c1a3992.r2.dev/form_guide/main.jpg"},{"type":"template","altText":"ご希望の店舗をお選びください","template":{"type":"carousel","imageAspectRatio":"rectangle","imageSize":"cover","columns":[{"thumbnailImageUrl":"https://pub-8dd04c3f08434d8a9435eea45c1a3992.r2.dev/stores/keido.jpg","title":"経堂コルティ店","text":"東京都世田谷区／小田急線「経堂駅」直結","actions":[{"type":"uri","label":"予約する","uri":"https://denba-4cshd.com/l_inquiry/?store=2&menu=1&ad_code=6"}]},{"thumbnailImageUrl":"https://pub-8dd04c3f08434d8a9435eea45c1a3992.r2.dev/stores/urawa.jpg","title":"イオンモール浦和美園店","text":"埼玉県さいたま市緑区／浦和美園駅 徒歩3分","actions":[{"type":"uri","label":"予約する","uri":"https://denba-4cshd.com/l_inquiry/?store=1&menu=1&ad_code=6"}]}]}}]}',
  updated_at = datetime('now', '+9 hours')
WHERE payload = 'store_select_carousel';
