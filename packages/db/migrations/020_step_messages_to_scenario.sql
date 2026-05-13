-- Migration 020: step_messages → scenarios/scenario_steps 移行
-- DENBAラウンジ登録ステップ配信（旧 step_messages）をシナリオシステムに移行
-- user_step_status にアクティブユーザー 0 件のため既存ユーザー移行は不要

-- 0. scenario_steps に不足カラムを追加（TypeScript インターフェースに合わせる）
ALTER TABLE scenario_steps ADD COLUMN condition_type TEXT;
ALTER TABLE scenario_steps ADD COLUMN condition_value TEXT;
ALTER TABLE scenario_steps ADD COLUMN next_step_on_false INTEGER;

-- 1. シナリオ作成（DENBAラウンジ専用・友だち追加トリガー）
INSERT INTO scenarios (id, name, description, trigger_type, trigger_tag_id, line_account_id, is_active, created_at, updated_at)
VALUES (
  'sce-denba-step-001',
  'DENBAラウンジ 登録ステップ配信',
  '友だち追加後 Day0/1/3/7/14 に自動送信するステップメッセージ（旧 step_messages から移行）',
  'friend_add',
  NULL,
  'dc316237-52ee-434e-bff1-addca7cde55e',
  1,
  datetime('now', '+9 hours'),
  datetime('now', '+9 hours')
);

-- 2. ステップ作成
-- delay_minutes は「前ステップ送信後からの分数」
-- Day0(0min) → Day1(+1440min) → Day3(+2880min) → Day7(+5760min) → Day14(+10080min)

-- Step 1: Day0 即時送信（友だち追加直後）
INSERT INTO scenario_steps (id, scenario_id, step_order, delay_minutes, message_type, message_content, condition_type, condition_value, next_step_on_false, created_at)
VALUES (
  'sst-denba-day0',
  'sce-denba-step-001',
  1,
  0,
  'text',
  '🌿 DENBAラウンジ【公式】へようこそ！

友だち追加ありがとうございます。
DENBAラウンジは、特殊電界技術「DENBA Health」で
心とカラダを整える"完全個室"のリラクゼーション空間です。

▼ 下のメニューから今すぐご予約いただけます
　①「ご予約」をタップ
　② 店舗（経堂／浦和美園）を選択
　③ ご希望日時をお選びください

初回体験は約60分。
おひとりおひとりに寄り添う時間をご用意してお待ちしております🌸

ご不明点はメニュー「FAQ」をご覧ください。',
  NULL, NULL, NULL,
  datetime('now', '+9 hours')
);

-- Step 2: Day1（友だち追加翌日 / 前ステップから 1440分後）
INSERT INTO scenario_steps (id, scenario_id, step_order, delay_minutes, message_type, message_content, condition_type, condition_value, next_step_on_false, created_at)
VALUES (
  'sst-denba-day1',
  'sce-denba-step-001',
  2,
  1440,
  'text',
  '🌿 DENBA Healthって、どんな体験？

「眠りが浅い」「疲れがとれない」「冷えやコリがつらい」
そんなお悩みに寄り添うのが、DENBAラウンジです。

▼ 特殊電界（DENBA波）に包まれることで…
　✓ 深いリラックス状態へ
　✓ 体感温度が上がりポカポカに
　✓ 60分横になるだけ・着衣のままOK

実際の店内・施術の様子はこちら👇
https://denba-4cshd.com/lounge/lp/line-step/

「自分にも合うかな？」と感じた方は、
メニューの「ご予約」から初回体験をお試しください🌸',
  NULL, NULL, NULL,
  datetime('now', '+9 hours')
);

-- Step 3: Day3（前ステップから 2880分後 = 2日後）
INSERT INTO scenario_steps (id, scenario_id, step_order, delay_minutes, message_type, message_content, condition_type, condition_value, next_step_on_false, created_at)
VALUES (
  'sst-denba-day3',
  'sce-denba-step-001',
  3,
  2880,
  'text',
  '💬 DENBAラウンジ ご利用者さまの声

▼ 60代女性・経堂店
「終わったあと、足の先までポカポカでした。
　久しぶりに朝までぐっすり眠れて驚きです」

▼ 50代男性・浦和美園店
「整体やマッサージとは全く別物。
　じわっと体の奥から温まる感覚で、毎週通いたくなる」

▼ 70代女性・経堂店
「個室で静かに横になれるのが何よりの贅沢。
　通うほどに体調が整っていくのを感じます」

ご自身でも体感してみませんか？
▼ 下メニュー「ご予約」からお気軽にどうぞ🌸',
  NULL, NULL, NULL,
  datetime('now', '+9 hours')
);

-- Step 4: Day7（前ステップから 5760分後 = 4日後）
INSERT INTO scenario_steps (id, scenario_id, step_order, delay_minutes, message_type, message_content, condition_type, condition_value, next_step_on_false, created_at)
VALUES (
  'sst-denba-day7',
  'sce-denba-step-001',
  4,
  5760,
  'text',
  '✨ まだ間に合います｜初回体験のご案内

DENBAラウンジを「気になっている」皆さまへ。
初めての方限定で、お得にお試しいただけます。

▼ 初回体験プラン
　60分 ／ 完全個室 ／ 着衣のままOK
　経堂店・浦和美園店 どちらもご予約可能

「平日の昼間が空いている」
「仕事帰りに立ち寄りたい」
そんなご希望もお気軽にご相談ください。

▼ ご予約は下メニュー「ご予約」から30秒
　空き状況をその場でご確認いただけます🌸',
  NULL, NULL, NULL,
  datetime('now', '+9 hours')
);

-- Step 5: Day14（前ステップから 10080分後 = 7日後）
INSERT INTO scenario_steps (id, scenario_id, step_order, delay_minutes, message_type, message_content, condition_type, condition_value, next_step_on_false, created_at)
VALUES (
  'sst-denba-day14',
  'sce-denba-step-001',
  5,
  10080,
  'text',
  '🌸 DENBAラウンジから最後のご案内

友だち追加から2週間、いかがお過ごしでしたか？
「予約まではちょっと…」という方も、
まずは情報だけでもお役立ていただければ嬉しいです。

▼ こんな使い方もできます
　・「FAQ」… よくあるご質問・料金・所要時間
　・「DENBAとは」… 技術や体験内容を詳しくご紹介
　・「店舗一覧」… アクセス・営業時間のご確認

体験をご検討の際は、いつでも下メニュー「ご予約」から。
皆さまのご来店を、心よりお待ちしております🌿',
  NULL, NULL, NULL,
  datetime('now', '+9 hours')
);

-- 3. 旧 step_messages を無効化（物理削除せず is_active=0 で保持）
UPDATE step_messages SET is_active = 0, updated_at = datetime('now', '+9 hours');
