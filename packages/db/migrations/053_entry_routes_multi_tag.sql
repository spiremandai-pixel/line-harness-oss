-- Migration 022: entry_routes に tag_id_2 / tag_id_3 を追加（複数タグ対応）
-- + 離脱ポップ用タグ4種 + 8つの流入経路を登録

-- ① カラム追加
ALTER TABLE entry_routes ADD COLUMN tag_id_2 TEXT REFERENCES tags(id) ON DELETE SET NULL;
ALTER TABLE entry_routes ADD COLUMN tag_id_3 TEXT REFERENCES tags(id) ON DELETE SET NULL;

-- ② 新規タグ（検索エンジン別・ページ種別）
INSERT OR IGNORE INTO tags (id, name, color, created_at) VALUES
  ('tag-src-search-google', 'src:search_google', '#4285F4', datetime('now','+9 hours')),
  ('tag-src-search-yahoo',  'src:search_yahoo',  '#720E9E', datetime('now','+9 hours')),
  ('tag-src-lp-popup',      'src:lp_popup',      '#F97316', datetime('now','+9 hours')),
  ('tag-src-form-popup',    'src:form_popup',     '#0EA5E9', datetime('now','+9 hours'));

-- ③ 8つの entry_routes（DENBAラウンジ所属）
--    tag_id   = ページ種別（lp_popup / form_popup）
--    tag_id_2 = 店舗（store:kyodo / store:uraamisono）
--    tag_id_3 = 検索エンジン（src:search_google / src:search_yahoo）

INSERT OR IGNORE INTO entry_routes
  (id, ref_code, name, tag_id, tag_id_2, tag_id_3, line_account_id, is_active, created_at, updated_at)
VALUES
  -- 記事LP × 経堂
  ('route-lp-kyodo-gss', 'lp-kyodo-gss', '記事LP離脱ポップ・経堂・Google検索',
   'tag-src-lp-popup', 'tag-store-kyodo', 'tag-src-search-google',
   'dc316237-52ee-434e-bff1-addca7cde55e', 1, datetime('now','+9 hours'), datetime('now','+9 hours')),

  ('route-lp-kyodo-yss', 'lp-kyodo-yss', '記事LP離脱ポップ・経堂・Yahoo検索',
   'tag-src-lp-popup', 'tag-store-kyodo', 'tag-src-search-yahoo',
   'dc316237-52ee-434e-bff1-addca7cde55e', 1, datetime('now','+9 hours'), datetime('now','+9 hours')),

  -- 記事LP × 浦和美園
  ('route-lp-urawa-gss', 'lp-urawa-gss', '記事LP離脱ポップ・浦和美園・Google検索',
   'tag-src-lp-popup', 'tag-store-uraamisono', 'tag-src-search-google',
   'dc316237-52ee-434e-bff1-addca7cde55e', 1, datetime('now','+9 hours'), datetime('now','+9 hours')),

  ('route-lp-urawa-yss', 'lp-urawa-yss', '記事LP離脱ポップ・浦和美園・Yahoo検索',
   'tag-src-lp-popup', 'tag-store-uraamisono', 'tag-src-search-yahoo',
   'dc316237-52ee-434e-bff1-addca7cde55e', 1, datetime('now','+9 hours'), datetime('now','+9 hours')),

  -- 予約フォーム × 浦和美園
  ('route-form-urawa-g', 'form-urawa-g', '予約フォーム離脱ポップ・浦和美園・Google検索',
   'tag-src-form-popup', 'tag-store-uraamisono', 'tag-src-search-google',
   'dc316237-52ee-434e-bff1-addca7cde55e', 1, datetime('now','+9 hours'), datetime('now','+9 hours')),

  ('route-form-urawa-y', 'form-urawa-y', '予約フォーム離脱ポップ・浦和美園・Yahoo検索',
   'tag-src-form-popup', 'tag-store-uraamisono', 'tag-src-search-yahoo',
   'dc316237-52ee-434e-bff1-addca7cde55e', 1, datetime('now','+9 hours'), datetime('now','+9 hours')),

  -- 予約フォーム × 経堂
  ('route-form-kyodo-g', 'form-kyodo-g', '予約フォーム離脱ポップ・経堂・Google検索',
   'tag-src-form-popup', 'tag-store-kyodo', 'tag-src-search-google',
   'dc316237-52ee-434e-bff1-addca7cde55e', 1, datetime('now','+9 hours'), datetime('now','+9 hours')),

  ('route-form-kyodo-y', 'form-kyodo-y', '予約フォーム離脱ポップ・経堂・Yahoo検索',
   'tag-src-form-popup', 'tag-store-kyodo', 'tag-src-search-yahoo',
   'dc316237-52ee-434e-bff1-addca7cde55e', 1, datetime('now','+9 hours'), datetime('now','+9 hours'));
