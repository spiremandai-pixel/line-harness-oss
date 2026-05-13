-- Migration 021: line_account_id が NULL の配信を DENBAラウンジに帰属
-- 2026-04-24 に作成されたテスト配信はすべて DENBAラウンジでのテストのため

UPDATE broadcasts
SET line_account_id = 'dc316237-52ee-434e-bff1-addca7cde55e'
WHERE line_account_id IS NULL;
