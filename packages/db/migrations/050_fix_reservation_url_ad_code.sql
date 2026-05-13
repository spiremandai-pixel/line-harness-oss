-- Migration 019: 予約フォームURLのad_codeを6に統一（geo/spire計測）
-- ad_code=7（経堂仮）/ ad_code=8（浦和美園仮）→ ad_code=6 に一括置換

UPDATE rich_menu_postback_responses
SET
  body_json  = REPLACE(REPLACE(body_json, 'ad_code=7', 'ad_code=6'), 'ad_code=8', 'ad_code=6'),
  updated_at = datetime('now', '+9 hours')
WHERE payload IN ('store_select_carousel', 'store_list_carousel');
