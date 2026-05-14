-- =============================================================================
-- apply_upstream_009_040.sql
-- Safe incremental migration script for production D1 (line-crm).
-- Covers upstream migrations 009_token_expiry through 040_events_multi_account.
-- Skipped: 009_delivery_type (already applied), 015_auto_reply_account (already applied).
-- Skipped ALTER: 032_messages_log_line_account_id ADD COLUMN (line_account_id already exists).
-- Generated: 2026-05-14
-- =============================================================================

-- =============================================================================
-- 004_friend_metadata.sql (prerequisite — column not found in production DB)
-- =============================================================================
ALTER TABLE friends ADD COLUMN metadata TEXT NOT NULL DEFAULT '{}';

-- =============================================================================
-- 009_token_expiry.sql
-- Add token_expires_at to line_accounts
-- =============================================================================
ALTER TABLE line_accounts ADD COLUMN token_expires_at TEXT;

-- =============================================================================
-- 010_ad_conversions.sql
-- Add ad click ID columns to ref_tracking; create ad_platforms and ad_conversion_logs
-- =============================================================================
ALTER TABLE ref_tracking ADD COLUMN fbclid TEXT;
ALTER TABLE ref_tracking ADD COLUMN gclid TEXT;
ALTER TABLE ref_tracking ADD COLUMN twclid TEXT;
ALTER TABLE ref_tracking ADD COLUMN ttclid TEXT;
ALTER TABLE ref_tracking ADD COLUMN utm_source TEXT;
ALTER TABLE ref_tracking ADD COLUMN utm_medium TEXT;
ALTER TABLE ref_tracking ADD COLUMN utm_campaign TEXT;
ALTER TABLE ref_tracking ADD COLUMN user_agent TEXT;
ALTER TABLE ref_tracking ADD COLUMN ip_address TEXT;

CREATE TABLE IF NOT EXISTS ad_platforms (
  id           TEXT PRIMARY KEY,
  name         TEXT NOT NULL,
  display_name TEXT,
  config       TEXT NOT NULL DEFAULT '{}',
  is_active    INTEGER DEFAULT 1,
  created_at   TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%f', 'now', '+9 hours')),
  updated_at   TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%f', 'now', '+9 hours'))
);

CREATE TABLE IF NOT EXISTS ad_conversion_logs (
  id                  TEXT PRIMARY KEY,
  ad_platform_id      TEXT NOT NULL,
  friend_id           TEXT NOT NULL,
  conversion_point_id TEXT,
  event_name          TEXT NOT NULL,
  click_id            TEXT,
  click_id_type       TEXT,
  status              TEXT DEFAULT 'pending',
  request_body        TEXT,
  response_body       TEXT,
  error_message       TEXT,
  created_at          TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%f', 'now', '+9 hours'))
);

CREATE INDEX IF NOT EXISTS idx_ad_conversion_logs_platform ON ad_conversion_logs (ad_platform_id);
CREATE INDEX IF NOT EXISTS idx_ad_conversion_logs_friend ON ad_conversion_logs (friend_id);
CREATE INDEX IF NOT EXISTS idx_ad_conversion_logs_status ON ad_conversion_logs (status);

-- =============================================================================
-- 011_staff_members.sql
-- Create staff_members table
-- =============================================================================
CREATE TABLE IF NOT EXISTS staff_members (
  id         TEXT PRIMARY KEY,
  name       TEXT NOT NULL,
  email      TEXT,
  role       TEXT NOT NULL CHECK (role IN ('owner', 'admin', 'staff')),
  api_key    TEXT UNIQUE NOT NULL,
  is_active  INTEGER NOT NULL DEFAULT 1,
  created_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%f', 'now', '+9 hours')),
  updated_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%f', 'now', '+9 hours'))
);

CREATE UNIQUE INDEX IF NOT EXISTS idx_staff_members_api_key ON staff_members(api_key);
CREATE INDEX IF NOT EXISTS idx_staff_members_role ON staff_members(role);

-- =============================================================================
-- 012_alt_text.sql
-- Add alt_text to broadcasts
-- =============================================================================
ALTER TABLE broadcasts ADD COLUMN alt_text TEXT;

-- =============================================================================
-- 013_broadcast_insights.sql
-- Add line_request_id / aggregation_unit to broadcasts; create broadcast_insights
-- =============================================================================
ALTER TABLE broadcasts ADD COLUMN line_request_id TEXT;
ALTER TABLE broadcasts ADD COLUMN aggregation_unit TEXT;

CREATE TABLE IF NOT EXISTS broadcast_insights (
  id                  TEXT PRIMARY KEY,
  broadcast_id        TEXT NOT NULL REFERENCES broadcasts(id) ON DELETE CASCADE,
  delivered           INTEGER,
  unique_impression   INTEGER,
  unique_click        INTEGER,
  unique_media_played INTEGER,
  open_rate           REAL,
  click_rate          REAL,
  raw_response        TEXT,
  status              TEXT NOT NULL CHECK (status IN ('pending', 'ready', 'failed')),
  retry_count         INTEGER NOT NULL DEFAULT 0,
  fetched_at          TEXT,
  created_at          TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%f', 'now', '+9 hours'))
);

CREATE INDEX IF NOT EXISTS idx_broadcast_insights_broadcast_id ON broadcast_insights(broadcast_id);
CREATE INDEX IF NOT EXISTS idx_broadcast_insights_status ON broadcast_insights(status);

-- =============================================================================
-- 014_form_submit_message.sql
-- Add on_submit_message columns to forms
-- =============================================================================
ALTER TABLE forms ADD COLUMN on_submit_message_type TEXT CHECK (on_submit_message_type IN ('text', 'flex')) DEFAULT NULL;
ALTER TABLE forms ADD COLUMN on_submit_message_content TEXT DEFAULT NULL;

-- =============================================================================
-- 016_traffic_pools.sql
-- Create traffic_pools table
-- =============================================================================
CREATE TABLE IF NOT EXISTS traffic_pools (
  id TEXT PRIMARY KEY,
  slug TEXT UNIQUE NOT NULL,
  name TEXT NOT NULL,
  active_account_id TEXT NOT NULL REFERENCES line_accounts(id),
  is_active INTEGER NOT NULL DEFAULT 1,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL
);

-- =============================================================================
-- 017_form_webhook.sql
-- Add webhook columns to forms
-- =============================================================================
ALTER TABLE forms ADD COLUMN on_submit_webhook_url TEXT;
ALTER TABLE forms ADD COLUMN on_submit_webhook_headers TEXT;
ALTER TABLE forms ADD COLUMN on_submit_webhook_fail_message TEXT;

-- =============================================================================
-- 018_broadcast_queue.sql
-- Add batch_offset and segment_conditions to broadcasts
-- =============================================================================
ALTER TABLE broadcasts ADD COLUMN batch_offset INTEGER NOT NULL DEFAULT 0;
ALTER TABLE broadcasts ADD COLUMN segment_conditions TEXT;

-- =============================================================================
-- 018_message_templates.sql
-- Create message_templates table
-- (templates table already exists but message_templates is a separate table)
-- =============================================================================
CREATE TABLE IF NOT EXISTS message_templates (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  message_type TEXT NOT NULL CHECK (message_type IN ('text', 'flex')),
  message_content TEXT NOT NULL,
  created_at TEXT NOT NULL DEFAULT (datetime('now')),
  updated_at TEXT NOT NULL DEFAULT (datetime('now'))
);

-- =============================================================================
-- 019_pool_accounts.sql
-- Create pool_accounts table and migrate existing traffic_pools data
-- =============================================================================
CREATE TABLE IF NOT EXISTS pool_accounts (
  id TEXT PRIMARY KEY,
  pool_id TEXT NOT NULL REFERENCES traffic_pools(id) ON DELETE CASCADE,
  line_account_id TEXT NOT NULL REFERENCES line_accounts(id) ON DELETE CASCADE,
  is_active INTEGER NOT NULL DEFAULT 1,
  created_at TEXT NOT NULL DEFAULT (datetime('now')),
  UNIQUE(pool_id, line_account_id)
);

-- Migrate existing active_account_id to pool_accounts
INSERT OR IGNORE INTO pool_accounts (id, pool_id, line_account_id, is_active, created_at)
SELECT
  lower(hex(randomblob(4)) || '-' || hex(randomblob(2)) || '-' || hex(randomblob(2)) || '-' || hex(randomblob(2)) || '-' || hex(randomblob(6))),
  tp.id,
  tp.active_account_id,
  1,
  datetime('now')
FROM traffic_pools tp
WHERE tp.active_account_id IS NOT NULL;

-- =============================================================================
-- 006_tracked_links.sql (prerequisite — table was not in original schema.sql)
-- tracked_links and link_clicks were not in the initial production DB.
-- Create them before applying 020/021/022 which alter tracked_links.
-- =============================================================================
CREATE TABLE IF NOT EXISTS tracked_links (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  original_url TEXT NOT NULL,
  tag_id TEXT REFERENCES tags (id) ON DELETE SET NULL,
  scenario_id TEXT REFERENCES scenarios (id) ON DELETE SET NULL,
  is_active INTEGER NOT NULL DEFAULT 1,
  click_count INTEGER NOT NULL DEFAULT 0,
  created_at TEXT NOT NULL DEFAULT (datetime('now')),
  updated_at TEXT NOT NULL DEFAULT (datetime('now'))
);

CREATE TABLE IF NOT EXISTS link_clicks (
  id TEXT PRIMARY KEY,
  tracked_link_id TEXT NOT NULL REFERENCES tracked_links (id) ON DELETE CASCADE,
  friend_id TEXT REFERENCES friends (id) ON DELETE SET NULL,
  clicked_at TEXT NOT NULL DEFAULT (datetime('now'))
);

CREATE INDEX IF NOT EXISTS idx_link_clicks_link ON link_clicks (tracked_link_id);
CREATE INDEX IF NOT EXISTS idx_link_clicks_friend ON link_clicks (friend_id);

-- =============================================================================
-- 020_tracked_link_intro.sql
-- Add intro_template_id to tracked_links
-- =============================================================================
ALTER TABLE tracked_links ADD COLUMN intro_template_id TEXT REFERENCES message_templates (id) ON DELETE SET NULL;

-- =============================================================================
-- 021_tracked_link_reward.sql
-- Add reward_template_id to tracked_links
-- =============================================================================
ALTER TABLE tracked_links ADD COLUMN reward_template_id TEXT REFERENCES message_templates (id) ON DELETE SET NULL;

-- =============================================================================
-- 022_friend_first_tracked_link.sql
-- Add first_tracked_link_id to friends
-- =============================================================================
ALTER TABLE friends ADD COLUMN first_tracked_link_id TEXT REFERENCES tracked_links (id) ON DELETE SET NULL;

-- =============================================================================
-- 023_friend_ig_igsid.sql
-- Add ig_igsid to friends
-- =============================================================================
ALTER TABLE friends ADD COLUMN ig_igsid TEXT;
CREATE INDEX IF NOT EXISTS idx_friends_ig_igsid ON friends (ig_igsid);

-- =============================================================================
-- 024_form_opens.sql
-- Create form_opens table
-- =============================================================================
CREATE TABLE IF NOT EXISTS form_opens (
  id TEXT PRIMARY KEY,
  form_id TEXT NOT NULL,
  friend_id TEXT,
  friend_name TEXT,
  opened_at TEXT NOT NULL DEFAULT (datetime('now'))
);

CREATE INDEX IF NOT EXISTS idx_form_opens_form ON form_opens (form_id, opened_at);

-- =============================================================================
-- 025_account_settings.sql
-- Create account_settings table
-- =============================================================================
CREATE TABLE IF NOT EXISTS account_settings (
  id              TEXT PRIMARY KEY,
  line_account_id TEXT NOT NULL,
  key             TEXT NOT NULL,
  value           TEXT NOT NULL,
  created_at      TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%f', 'now', '+9 hours')),
  updated_at      TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%f', 'now', '+9 hours')),
  UNIQUE(line_account_id, key)
);

-- =============================================================================
-- 026_delivery_type_test.sql
-- No-op marker: 'test' delivery_type support (documented only; D1 CHECK not enforced on alter)
-- =============================================================================
SELECT 1;

-- =============================================================================
-- 027_dedup_delivery.sql
-- Fix duplicate delivery: clean up duplicates, recreate friend_scenarios with
-- updated CHECK constraint (adds 'delivering' status), add unique index
-- =============================================================================

-- Step 1: Clean up duplicate non-completed friend_scenarios
DELETE FROM friend_scenarios
WHERE status != 'completed' AND id NOT IN (
  SELECT id FROM (
    SELECT id, ROW_NUMBER() OVER (
      PARTITION BY friend_id, scenario_id
      ORDER BY
        CASE status WHEN 'active' THEN 0 WHEN 'delivering' THEN 0 ELSE 1 END,
        current_step_order DESC,
        started_at ASC
    ) AS rn
    FROM friend_scenarios
    WHERE status != 'completed'
  ) WHERE rn = 1
);

-- Step 2: Recreate friend_scenarios with updated CHECK (adds 'delivering' status)
CREATE TABLE friend_scenarios_new (
  id                 TEXT PRIMARY KEY,
  friend_id          TEXT NOT NULL REFERENCES friends (id) ON DELETE CASCADE,
  scenario_id        TEXT NOT NULL REFERENCES scenarios (id) ON DELETE CASCADE,
  current_step_order INTEGER NOT NULL DEFAULT 0,
  status             TEXT NOT NULL CHECK (status IN ('active', 'paused', 'completed', 'delivering')) DEFAULT 'active',
  started_at         TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%f', 'now', '+9 hours')),
  next_delivery_at   TEXT,
  updated_at         TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%f', 'now', '+9 hours')),
  line_account_id    TEXT
);

INSERT INTO friend_scenarios_new SELECT * FROM friend_scenarios;

DROP TABLE friend_scenarios;

ALTER TABLE friend_scenarios_new RENAME TO friend_scenarios;

-- Recreate indexes
CREATE INDEX IF NOT EXISTS idx_friend_scenarios_next_delivery_at ON friend_scenarios (next_delivery_at);
CREATE INDEX IF NOT EXISTS idx_friend_scenarios_status ON friend_scenarios (status);
CREATE INDEX IF NOT EXISTS idx_friend_scenarios_friend_id ON friend_scenarios (friend_id);
CREATE UNIQUE INDEX IF NOT EXISTS idx_friend_scenarios_unique ON friend_scenarios (friend_id, scenario_id) WHERE status != 'completed';

-- =============================================================================
-- 028_messages_log_source.sql
-- Add source column to messages_log and backfill
-- =============================================================================
ALTER TABLE messages_log ADD COLUMN source TEXT;

UPDATE messages_log SET source = 'user' WHERE direction = 'incoming';
UPDATE messages_log SET source = 'broadcast' WHERE direction = 'outgoing' AND broadcast_id IS NOT NULL;
UPDATE messages_log SET source = 'broadcast' WHERE direction = 'outgoing' AND delivery_type = 'test' AND source IS NULL;
UPDATE messages_log SET source = 'scenario' WHERE direction = 'outgoing' AND scenario_step_id IS NOT NULL AND source IS NULL;
UPDATE messages_log SET source = 'auto_reply' WHERE direction = 'outgoing' AND delivery_type = 'reply' AND source IS NULL;
UPDATE messages_log SET source = 'manual' WHERE source IS NULL AND direction = 'outgoing';

CREATE INDEX IF NOT EXISTS idx_messages_log_friend_source ON messages_log (friend_id, source);
CREATE INDEX IF NOT EXISTS idx_messages_log_friend_direction_created ON messages_log (friend_id, direction, created_at);

-- =============================================================================
-- 029_account_management_v2.sql
-- Part 1: Add country/role/display_order to line_accounts
-- Part 2: Recreate broadcasts table with expanded CHECK constraints and new columns
-- =============================================================================

-- Part 1: line_accounts extensions
ALTER TABLE line_accounts ADD COLUMN country TEXT;
ALTER TABLE line_accounts ADD COLUMN role TEXT;
ALTER TABLE line_accounts ADD COLUMN display_order INTEGER NOT NULL DEFAULT 0;

CREATE INDEX IF NOT EXISTS idx_line_accounts_display_order
  ON line_accounts (display_order, created_at);

UPDATE line_accounts SET display_order = (
  SELECT COUNT(*) FROM line_accounts la2
  WHERE la2.created_at < line_accounts.created_at
     OR (la2.created_at = line_accounts.created_at AND la2.id < line_accounts.id)
) WHERE display_order = 0;

-- Part 2: Recreate broadcasts with expanded CHECK constraints and new columns
-- (target_type expanded to include 'segment' and 'multi-account-dedup';
--  status expanded to include 'scheduled' and 'sending';
--  new columns: account_ids, dedup_priority, failed_account_ids)
-- NOTE: At this point broadcasts already has these columns from earlier ALTERs in this script:
--   alt_text, line_request_id, aggregation_unit, batch_offset, segment_conditions
CREATE TABLE broadcasts_new (
  id                 TEXT PRIMARY KEY,
  title              TEXT NOT NULL,
  message_type       TEXT NOT NULL CHECK (message_type IN ('text', 'image', 'flex')),
  message_content    TEXT NOT NULL,
  target_type        TEXT NOT NULL CHECK (target_type IN ('all', 'tag', 'segment', 'multi-account-dedup')) DEFAULT 'all',
  target_tag_id      TEXT REFERENCES tags (id) ON DELETE SET NULL,
  status             TEXT NOT NULL CHECK (status IN ('draft', 'scheduled', 'sending', 'sent')) DEFAULT 'draft',
  scheduled_at       TEXT,
  sent_at            TEXT,
  total_count        INTEGER NOT NULL DEFAULT 0,
  success_count      INTEGER NOT NULL DEFAULT 0,
  created_at         TEXT NOT NULL DEFAULT (datetime('now')),
  line_account_id    TEXT,
  alt_text           TEXT,
  line_request_id    TEXT,
  aggregation_unit   TEXT,
  batch_offset       INTEGER NOT NULL DEFAULT 0,
  segment_conditions TEXT,
  account_ids        TEXT CHECK (account_ids IS NULL OR json_valid(account_ids)),
  dedup_priority     TEXT CHECK (dedup_priority IS NULL OR json_valid(dedup_priority)),
  failed_account_ids TEXT CHECK (failed_account_ids IS NULL OR json_valid(failed_account_ids))
);

INSERT INTO broadcasts_new (
  id, title, message_type, message_content, target_type, target_tag_id, status,
  scheduled_at, sent_at, total_count, success_count, created_at,
  line_account_id, alt_text, line_request_id, aggregation_unit, batch_offset, segment_conditions
) SELECT
  id, title, message_type, message_content, target_type, target_tag_id, status,
  scheduled_at, sent_at, total_count, success_count, created_at,
  line_account_id, alt_text, line_request_id, aggregation_unit, batch_offset, segment_conditions
FROM broadcasts;

DROP TABLE broadcasts;
ALTER TABLE broadcasts_new RENAME TO broadcasts;

CREATE INDEX IF NOT EXISTS idx_broadcasts_status ON broadcasts (status);

-- =============================================================================
-- 030_dedup_progress.sql
-- Add dedup_progress to broadcasts
-- =============================================================================
ALTER TABLE broadcasts ADD COLUMN dedup_progress TEXT;

-- =============================================================================
-- 031_batch_lock_at.sql
-- Add batch_lock_at to broadcasts and backfill stuck rows
-- =============================================================================
ALTER TABLE broadcasts ADD COLUMN batch_lock_at TEXT;

UPDATE broadcasts
   SET batch_lock_at = strftime('%Y-%m-%dT%H:%M:%f', 'now', '+9 hours')
 WHERE status = 'sending' AND batch_offset = -1 AND batch_lock_at IS NULL;

-- =============================================================================
-- 032_messages_log_line_account_id.sql
-- SKIPPED ALTER: messages_log.line_account_id already exists in production.
-- Adding index only (CREATE INDEX IF NOT EXISTS is safe to re-run).
-- =============================================================================
CREATE INDEX IF NOT EXISTS idx_messages_log_broadcast_id ON messages_log(broadcast_id);

-- =============================================================================
-- 033_auto_replies_template_id.sql
-- Add template_id to auto_replies
-- =============================================================================
ALTER TABLE auto_replies ADD COLUMN template_id TEXT
  REFERENCES templates(id) ON DELETE SET NULL;

CREATE INDEX IF NOT EXISTS idx_auto_replies_template_id
  ON auto_replies(template_id);

-- =============================================================================
-- 034_webhook_secret_required.sql
-- Deactivate webhooks without valid secrets (fail-closed security hardening)
-- =============================================================================
UPDATE incoming_webhooks
   SET is_active = 0,
       updated_at = strftime('%Y-%m-%dT%H:%M:%S', 'now', '+9 hours') || '.000+09:00'
 WHERE secret IS NULL
    OR LENGTH(secret) < 32;

UPDATE outgoing_webhooks
   SET is_active = 0,
       updated_at = strftime('%Y-%m-%dT%H:%M:%S', 'now', '+9 hours') || '.000+09:00'
 WHERE secret IS NULL
    OR LENGTH(secret) < 32
    OR url IS NULL
    OR url NOT LIKE 'https://_%'
    OR url LIKE 'https://:%'
    OR url LIKE 'https://?%'
    OR url LIKE 'https://#%'
    OR url LIKE 'https://[%';

-- =============================================================================
-- 035_rich_menu_groups.sql
-- Create rich_menu_groups, rich_menu_pages, rich_menu_areas tables
-- =============================================================================
CREATE TABLE IF NOT EXISTS rich_menu_groups (
  id                 TEXT PRIMARY KEY,
  account_id         TEXT NOT NULL REFERENCES line_accounts(id) ON DELETE CASCADE,
  name               TEXT NOT NULL,
  chat_bar_text      TEXT NOT NULL,
  size               TEXT NOT NULL CHECK (size IN ('large','compact')),
  default_page_id    TEXT,
  is_default_for_all INTEGER NOT NULL DEFAULT 0,
  status             TEXT NOT NULL DEFAULT 'draft' CHECK (status IN ('draft','published')),
  publishing_at      TEXT,
  created_at         TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%f', 'now', '+9 hours')),
  updated_at         TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%f', 'now', '+9 hours'))
);

CREATE TABLE IF NOT EXISTS rich_menu_pages (
  id                 TEXT PRIMARY KEY,
  group_id           TEXT NOT NULL REFERENCES rich_menu_groups(id) ON DELETE CASCADE,
  order_index        INTEGER NOT NULL,
  name               TEXT NOT NULL,
  alias_id           TEXT NOT NULL,
  line_richmenu_id   TEXT,
  image_r2_key       TEXT,
  image_content_type TEXT,
  created_at         TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%f', 'now', '+9 hours')),
  updated_at         TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%f', 'now', '+9 hours')),
  UNIQUE (group_id, order_index)
);

CREATE TABLE IF NOT EXISTS rich_menu_areas (
  id              TEXT PRIMARY KEY,
  page_id         TEXT NOT NULL REFERENCES rich_menu_pages(id) ON DELETE CASCADE,
  bounds_x        INTEGER NOT NULL,
  bounds_y        INTEGER NOT NULL,
  bounds_width    INTEGER NOT NULL,
  bounds_height   INTEGER NOT NULL,
  action_type     TEXT NOT NULL CHECK (action_type IN ('uri','message','postback','richmenuswitch')),
  action_data     TEXT NOT NULL,
  created_at      TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%f', 'now', '+9 hours')),
  updated_at      TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%f', 'now', '+9 hours'))
);

CREATE INDEX IF NOT EXISTS idx_rich_menu_pages_group  ON rich_menu_pages(group_id, order_index);
CREATE INDEX IF NOT EXISTS idx_rich_menu_areas_page   ON rich_menu_areas(page_id);
CREATE INDEX IF NOT EXISTS idx_rich_menu_groups_account ON rich_menu_groups(account_id, status);

-- =============================================================================
-- 036_booking.sql
-- Create booking-related tables: menus, staff, staff_menus, staff_shifts,
-- bookings, booking_idempotency_keys, booking_reminders
-- =============================================================================
CREATE TABLE IF NOT EXISTS menus (
  id                    TEXT PRIMARY KEY,
  line_account_id       TEXT NOT NULL,
  name                  TEXT NOT NULL,
  category_label        TEXT,
  description           TEXT,
  duration_minutes      INTEGER NOT NULL,
  buffer_after_minutes  INTEGER NOT NULL DEFAULT 0,
  base_price            INTEGER NOT NULL,
  sort_order            INTEGER NOT NULL DEFAULT 0,
  is_active             INTEGER NOT NULL DEFAULT 1,
  deleted_at            TEXT,
  created_at            TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%f', 'now', '+9 hours')),
  updated_at            TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%f', 'now', '+9 hours')),
  FOREIGN KEY (line_account_id) REFERENCES line_accounts(id)
);
CREATE INDEX IF NOT EXISTS idx_menus_account_sort ON menus (line_account_id, sort_order);

CREATE TABLE IF NOT EXISTS staff (
  id                       TEXT PRIMARY KEY,
  line_account_id          TEXT NOT NULL,
  name                     TEXT NOT NULL,
  display_name             TEXT NOT NULL,
  role                     TEXT,
  profile_image_url        TEXT,
  bio                      TEXT,
  sort_order               INTEGER NOT NULL DEFAULT 0,
  is_designation_optional  INTEGER NOT NULL DEFAULT 0,
  is_active                INTEGER NOT NULL DEFAULT 1,
  deleted_at               TEXT,
  created_at               TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%f', 'now', '+9 hours')),
  updated_at               TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%f', 'now', '+9 hours')),
  FOREIGN KEY (line_account_id) REFERENCES line_accounts(id)
);
CREATE INDEX IF NOT EXISTS idx_staff_account_sort ON staff (line_account_id, sort_order);

CREATE TABLE IF NOT EXISTS staff_menus (
  staff_id                  TEXT NOT NULL,
  menu_id                   TEXT NOT NULL,
  is_offered                INTEGER NOT NULL DEFAULT 1,
  override_duration_minutes INTEGER,
  override_price            INTEGER,
  PRIMARY KEY (staff_id, menu_id),
  FOREIGN KEY (staff_id) REFERENCES staff(id),
  FOREIGN KEY (menu_id) REFERENCES menus(id)
);

CREATE TABLE IF NOT EXISTS staff_shifts (
  id          TEXT PRIMARY KEY,
  staff_id    TEXT NOT NULL,
  work_date   TEXT NOT NULL,
  start_time  TEXT NOT NULL,
  end_time    TEXT NOT NULL,
  created_at  TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%f', 'now', '+9 hours')),
  updated_at  TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%f', 'now', '+9 hours')),
  UNIQUE (staff_id, work_date),
  FOREIGN KEY (staff_id) REFERENCES staff(id)
);
CREATE INDEX IF NOT EXISTS idx_shifts_staff_date ON staff_shifts (staff_id, work_date);

CREATE TABLE IF NOT EXISTS bookings (
  id                      TEXT PRIMARY KEY,
  line_account_id         TEXT NOT NULL,
  friend_id               TEXT NOT NULL,
  staff_id                TEXT NOT NULL,
  menu_id                 TEXT NOT NULL,
  starts_at               TEXT NOT NULL,
  ends_at                 TEXT NOT NULL,
  block_ends_at           TEXT NOT NULL,
  status                  TEXT NOT NULL CHECK (status IN ('requested','confirmed','rejected','expired','cancelled','completed','no_show')),
  customer_note           TEXT,
  internal_note           TEXT,
  price_at_booking        INTEGER NOT NULL,
  requested_at            TEXT NOT NULL,
  decided_at              TEXT,
  decided_by_staff_id     TEXT,
  external_event_id       TEXT,
  external_calendar_id    TEXT,
  created_at              TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%f', 'now', '+9 hours')),
  updated_at              TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%f', 'now', '+9 hours')),
  FOREIGN KEY (line_account_id) REFERENCES line_accounts(id),
  FOREIGN KEY (friend_id) REFERENCES friends(id),
  FOREIGN KEY (staff_id) REFERENCES staff(id),
  FOREIGN KEY (menu_id) REFERENCES menus(id)
);
CREATE INDEX IF NOT EXISTS idx_bookings_account_status_starts ON bookings (line_account_id, status, starts_at);
CREATE INDEX IF NOT EXISTS idx_bookings_staff_overlap ON bookings (staff_id, status, starts_at, block_ends_at);
CREATE INDEX IF NOT EXISTS idx_bookings_friend_starts ON bookings (friend_id, starts_at DESC);

CREATE TABLE IF NOT EXISTS booking_idempotency_keys (
  key              TEXT PRIMARY KEY,
  line_account_id  TEXT NOT NULL,
  friend_id        TEXT NOT NULL,
  response_status  INTEGER NOT NULL,
  response_body    TEXT NOT NULL,
  created_at       TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%f', 'now', '+9 hours')),
  expires_at       TEXT NOT NULL
);
CREATE INDEX IF NOT EXISTS idx_idempotency_expires ON booking_idempotency_keys (expires_at);

CREATE TABLE IF NOT EXISTS booking_reminders (
  id            TEXT PRIMARY KEY,
  booking_id    TEXT NOT NULL,
  kind          TEXT NOT NULL CHECK (kind IN ('day_before','hours_before')),
  scheduled_at  TEXT NOT NULL,
  sent_at       TEXT,
  status        TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending','sent','failed','failed_permanent','cancelled')),
  retry_count   INTEGER NOT NULL DEFAULT 0,
  last_error    TEXT,
  FOREIGN KEY (booking_id) REFERENCES bookings(id)
);
CREATE INDEX IF NOT EXISTS idx_reminders_status_scheduled ON booking_reminders (status, scheduled_at);

-- =============================================================================
-- 037_event_booking.sql
-- Create event booking tables: events, event_slots, event_bookings,
-- event_booking_reminders, event_booking_idempotency_keys
-- =============================================================================
CREATE TABLE IF NOT EXISTS events (
  id                            TEXT PRIMARY KEY,
  line_account_id               TEXT NOT NULL,
  name                          TEXT NOT NULL,
  venue_name                    TEXT,
  venue_url                     TEXT,
  image_url                     TEXT,
  description                   TEXT,
  description_centered          INTEGER NOT NULL DEFAULT 0,
  max_bookings_per_friend       INTEGER,
  requires_approval             INTEGER NOT NULL DEFAULT 0,
  cancel_deadline_hours_before  INTEGER,
  reminder_day_before_enabled   INTEGER NOT NULL DEFAULT 1,
  reminder_hours_before         INTEGER,
  is_published                  INTEGER NOT NULL DEFAULT 0,
  folder_id                     TEXT,
  sort_order                    INTEGER NOT NULL DEFAULT 0,
  deleted_at                    TEXT,
  created_at                    TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%f', 'now', '+9 hours')),
  updated_at                    TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%f', 'now', '+9 hours')),
  FOREIGN KEY (line_account_id) REFERENCES line_accounts(id)
);
CREATE INDEX IF NOT EXISTS idx_events_account_published_sort ON events (line_account_id, is_published, sort_order);

CREATE TABLE IF NOT EXISTS event_slots (
  id          TEXT PRIMARY KEY,
  event_id    TEXT NOT NULL,
  starts_at   TEXT NOT NULL,
  ends_at     TEXT NOT NULL,
  capacity    INTEGER,
  is_active   INTEGER NOT NULL DEFAULT 1,
  sort_order  INTEGER NOT NULL DEFAULT 0,
  deleted_at  TEXT,
  created_at  TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%f', 'now', '+9 hours')),
  updated_at  TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%f', 'now', '+9 hours')),
  FOREIGN KEY (event_id) REFERENCES events(id)
);
CREATE INDEX IF NOT EXISTS idx_event_slots_event_starts ON event_slots (event_id, starts_at);

CREATE TABLE IF NOT EXISTS event_bookings (
  id                    TEXT PRIMARY KEY,
  line_account_id       TEXT NOT NULL,
  event_id              TEXT NOT NULL,
  slot_id               TEXT NOT NULL,
  friend_id             TEXT NOT NULL,
  status                TEXT NOT NULL CHECK (status IN ('requested','confirmed','rejected','cancelled','expired','no_show','attended')),
  customer_note         TEXT,
  internal_note         TEXT,
  requested_at          TEXT NOT NULL,
  decided_at            TEXT,
  decided_by_staff_id   TEXT,
  cancelled_at          TEXT,
  cancelled_by          TEXT CHECK (cancelled_by IN ('friend','admin','system')),
  created_at            TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%f', 'now', '+9 hours')),
  updated_at            TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%f', 'now', '+9 hours')),
  FOREIGN KEY (line_account_id) REFERENCES line_accounts(id),
  FOREIGN KEY (event_id) REFERENCES events(id),
  FOREIGN KEY (slot_id) REFERENCES event_slots(id),
  FOREIGN KEY (friend_id) REFERENCES friends(id)
);
CREATE INDEX IF NOT EXISTS idx_event_bookings_account_status_event ON event_bookings (line_account_id, status, event_id);
CREATE INDEX IF NOT EXISTS idx_event_bookings_slot_status ON event_bookings (slot_id, status);
CREATE INDEX IF NOT EXISTS idx_event_bookings_friend_requested ON event_bookings (friend_id, requested_at DESC);

CREATE TABLE IF NOT EXISTS event_booking_reminders (
  id            TEXT PRIMARY KEY,
  booking_id    TEXT NOT NULL,
  kind          TEXT NOT NULL CHECK (kind IN ('day_before','hours_before')),
  scheduled_at  TEXT NOT NULL,
  sent_at       TEXT,
  status        TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending','sent','failed','failed_permanent','cancelled')),
  retry_count   INTEGER NOT NULL DEFAULT 0,
  last_error    TEXT,
  FOREIGN KEY (booking_id) REFERENCES event_bookings(id)
);
CREATE INDEX IF NOT EXISTS idx_event_booking_reminders_status_scheduled ON event_booking_reminders (status, scheduled_at);

CREATE TABLE IF NOT EXISTS event_booking_idempotency_keys (
  key              TEXT PRIMARY KEY,
  line_account_id  TEXT NOT NULL,
  friend_id        TEXT NOT NULL,
  response_status  INTEGER NOT NULL,
  response_body    TEXT NOT NULL,
  created_at       TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%f', 'now', '+9 hours')),
  expires_at       TEXT NOT NULL
);
CREATE INDEX IF NOT EXISTS idx_event_booking_idempotency_expires ON event_booking_idempotency_keys (expires_at);

-- =============================================================================
-- 037_scenario_delivery_mode.sql
-- Add delivery_mode to scenarios, and offset_days / offset_minutes / delivery_time
-- to scenario_steps. (Columns confirmed absent from production DB 2026-05-14)
-- =============================================================================
ALTER TABLE scenarios ADD COLUMN delivery_mode TEXT NOT NULL DEFAULT 'relative'
  CHECK (delivery_mode IN ('relative', 'elapsed', 'absolute_time'));
ALTER TABLE scenario_steps ADD COLUMN offset_days INTEGER;
ALTER TABLE scenario_steps ADD COLUMN offset_minutes INTEGER;
ALTER TABLE scenario_steps ADD COLUMN delivery_time TEXT;

-- =============================================================================
-- 038_entry_routes_pool_and_push.sql
-- Add pool_id, intro_template_id, run_account_friend_add_scenarios to entry_routes
-- =============================================================================
ALTER TABLE entry_routes
  ADD COLUMN pool_id TEXT REFERENCES traffic_pools (id) ON DELETE SET NULL;

ALTER TABLE entry_routes
  ADD COLUMN intro_template_id TEXT REFERENCES message_templates (id) ON DELETE SET NULL;

ALTER TABLE entry_routes
  ADD COLUMN run_account_friend_add_scenarios INTEGER NOT NULL DEFAULT 1;

CREATE INDEX IF NOT EXISTS idx_entry_routes_pool ON entry_routes (pool_id);

-- =============================================================================
-- 038_scenario_templates_and_stats.sql
-- Add template_id and on_reach_tag_id to scenario_steps;
-- add template_id_at_send to messages_log
-- =============================================================================
ALTER TABLE scenario_steps ADD COLUMN template_id TEXT REFERENCES templates(id) ON DELETE SET NULL;
ALTER TABLE scenario_steps ADD COLUMN on_reach_tag_id TEXT REFERENCES tags(id) ON DELETE SET NULL;

ALTER TABLE messages_log ADD COLUMN template_id_at_send TEXT;

-- =============================================================================
-- 039_default_main_pool.sql
-- Create default 'main' traffic pool if none exists; enroll all accounts
-- =============================================================================
INSERT OR IGNORE INTO traffic_pools (
  id, slug, name, active_account_id, is_active, created_at, updated_at
)
SELECT
  lower(hex(randomblob(16))),
  'main',
  'メインプール',
  (SELECT id FROM line_accounts ORDER BY created_at ASC LIMIT 1),
  1,
  datetime('now'),
  datetime('now')
WHERE NOT EXISTS (SELECT 1 FROM traffic_pools WHERE slug = 'main')
  AND EXISTS (SELECT 1 FROM line_accounts);

INSERT OR IGNORE INTO pool_accounts (
  id, pool_id, line_account_id, is_active, created_at
)
SELECT
  lower(hex(randomblob(16))),
  (SELECT id FROM traffic_pools WHERE slug = 'main'),
  la.id,
  1,
  datetime('now')
FROM line_accounts la
WHERE EXISTS (SELECT 1 FROM traffic_pools WHERE slug = 'main')
  AND NOT EXISTS (
    SELECT 1 FROM pool_accounts pa WHERE pa.line_account_id = la.id
  );

-- =============================================================================
-- 040_events_multi_account.sql
-- Add multi-account-dedup columns to events;
-- add identity_key to event_bookings and backfill; add index
-- =============================================================================
ALTER TABLE events ADD COLUMN target_type TEXT NOT NULL DEFAULT 'single'
  CHECK (target_type IN ('single', 'multi-account-dedup'));
ALTER TABLE events ADD COLUMN account_ids TEXT
  CHECK (account_ids IS NULL OR json_valid(account_ids));
ALTER TABLE events ADD COLUMN dedup_priority TEXT
  CHECK (dedup_priority IS NULL OR json_valid(dedup_priority));
ALTER TABLE events ADD COLUMN failed_account_ids TEXT
  CHECK (failed_account_ids IS NULL OR json_valid(failed_account_ids));

ALTER TABLE event_bookings ADD COLUMN identity_key TEXT;
UPDATE event_bookings SET identity_key = 'solo:' || id WHERE identity_key IS NULL;

CREATE INDEX IF NOT EXISTS idx_event_bookings_identity_status
  ON event_bookings (event_id, identity_key, status);

-- =============================================================================
-- End of apply_upstream_009_040.sql
-- =============================================================================
