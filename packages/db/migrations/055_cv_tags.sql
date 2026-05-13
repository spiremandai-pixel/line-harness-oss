-- Migration 024: CV（コンバージョン）計測用タグ

INSERT OR IGNORE INTO tags (id, name, color, created_at) VALUES
  ('tag-cv-reserved',            'cv:reserved',            '#10B981', datetime('now', '+9 hours')),
  ('tag-cv-reserved-kyodo',      'cv:reserved_kyodo',      '#059669', datetime('now', '+9 hours')),
  ('tag-cv-reserved-uraamisono', 'cv:reserved_uraamisono', '#047857', datetime('now', '+9 hours')),
  ('tag-cv-inquiry',             'cv:inquiry',             '#3B82F6', datetime('now', '+9 hours'));
