-- Migration 014: カルーセル thumbnailImageUrl を R2 実URL に置換
UPDATE rich_menu_postback_responses
SET
  body_json = REPLACE(
    REPLACE(body_json,
      'https://placehold.co/1024x1024/1E3A8A/FFFFFF.jpg',
      'https://pub-8dd04c3f08434d8a9435eea45c1a3992.r2.dev/stores/keido.jpg'
    ),
    'https://placehold.co/1024x1024/1E4A8A/FFFFFF.jpg',
    'https://pub-8dd04c3f08434d8a9435eea45c1a3992.r2.dev/stores/urawa.jpg'
  ),
  updated_at = datetime('now', '+9 hours')
WHERE payload IN ('store_select_carousel', 'store_list_carousel');
