-- Migration 032: conversion_points に line_account_id を追加してアカウント別に切り分け

ALTER TABLE conversion_points ADD COLUMN line_account_id TEXT REFERENCES line_accounts(id) ON DELETE CASCADE;

-- 既存のDENBAラウンジ CVポイントにアカウントIDを紐づけ
UPDATE conversion_points
SET line_account_id = 'dc316237-52ee-434e-bff1-addca7cde55e'
WHERE id IN ('cv-point-reserved', 'cv-point-reserved-kyodo', 'cv-point-reserved-uraamisono');
