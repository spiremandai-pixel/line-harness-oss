# 自動タグ付け 現状調査レポート
**対象プロジェクト**: LINE Harness OSS（DENBAラウンジ運用）  
**調査日**: 2026-05-08  
**調査範囲**: D1スキーマ / Workerルート / サービス層

---

## 1. 現状調査 — タグ関連テーブルと自動付与ポイント

### 1-1. タグ関連 D1 テーブル構造

#### `tags` テーブル（`packages/db/schema.sql` L.26）
```
id         TEXT PRIMARY KEY
name       TEXT UNIQUE NOT NULL
color      TEXT NOT NULL DEFAULT '#3B82F6'
created_at TEXT
```
タグマスタ。UIから手動作成のみ。現在 DB にシード済みタグは**ゼロ**（空テーブル）。

#### `friend_tags` テーブル（`packages/db/schema.sql` L.36）
```
friend_id   TEXT → friends.id
tag_id      TEXT → tags.id
assigned_at TEXT
PRIMARY KEY (friend_id, tag_id)
```
多対多ジャンクション。`assigned_at` で付与日時を記録。インデックス: `idx_friend_tags_tag_id`。

#### `entry_routes` テーブル（`packages/db/migrations/003_entry_routes.sql` L.2）
```
id           TEXT PRIMARY KEY
ref_code     TEXT UNIQUE NOT NULL    -- QR/URL パラメータ ?ref=xxx
name         TEXT NOT NULL
tag_id       TEXT → tags.id ON DELETE SET NULL
scenario_id  TEXT → scenarios.id ON DELETE SET NULL
redirect_url TEXT
is_active    INTEGER DEFAULT 1
```
`ref_code` → `tag_id` のマッピング。流入経路ごとにタグ付けを定義する設計。

#### `ref_tracking` テーブル（`packages/db/migrations/003_entry_routes.sql` L.17）
```
id             TEXT PRIMARY KEY
ref_code       TEXT NOT NULL
friend_id      TEXT → friends.id
entry_route_id TEXT → entry_routes.id ON DELETE SET NULL
source_url     TEXT
created_at     TEXT
```
誰がどの ref_code で入ってきたかのアクセスログ。

#### `automations` テーブル（`packages/db/migrations/002_round3.sql` L.261）
```
id          TEXT PRIMARY KEY
name        TEXT NOT NULL
event_type  TEXT NOT NULL    -- friend_add / tag_change / cv_fire / message_received ...
conditions  TEXT DEFAULT '{}' -- JSON: 条件オブジェクト
actions     TEXT DEFAULT '[]' -- JSON配列: [{type:"add_tag",params:{tagId:"..."}}, ...]
is_active   INTEGER DEFAULT 1
priority    INTEGER DEFAULT 0
```
IF-THEN 自動化。`add_tag` / `remove_tag` アクションタイプが実装済み。

#### `forms` テーブル（`apps/worker/src/routes/forms.ts` L.25）
```
on_submit_tag_id      TEXT   -- フォーム送信時に自動付与するタグID
on_submit_scenario_id TEXT   -- フォーム送信時に自動登録するシナリオID
```

---

### 1-2. 既存の自動タグ付与トリガー（実装済み）

| # | トリガー条件 | ファイル・行番号 | 実装状態 |
|---|---|---|---|
| ① | LIFF `/auth/callback` — `?ref=xxx` が entry_routes に登録済み | `apps/worker/src/routes/liff.ts` L.316–323 | ✅ 動作中 |
| ② | フォーム送信 — `form.on_submit_tag_id` が設定済み | `apps/worker/src/routes/forms.ts` L.251–253 | ✅ 動作中 |
| ③ | 手動 API — `POST /api/friends/:id/tags` | `apps/worker/src/routes/friends.ts` L.178–213 | ✅ 動作中 |
| ④ | automations IF-THEN — `add_tag` アクション | `apps/worker/src/services/event-bus.ts` L.200–202 | ✅ 動作中（ルール登録待ち） |

**① の詳細フロー（LIFF ref_code 経由）**

```
LIFF URL: https://liff.line.me/xxxx?ref=kyodo-qr
    ↓
/auth/line  → state に ref パラメータを保存
    ↓
LINE OAuth → /auth/callback
    ↓
getEntryRouteByRefCode(db, ref)          ← entry_routes テーブル参照
    ↓
route.tag_id が存在すれば addTagToFriend(db, friend.id, route.tag_id)
    ↓（同時に）
recordRefTracking()                       ← ref_tracking にログ記録
friends.ref_code を UPDATE（初回のみ）
```

**④ automations の条件マッチング**（`event-bus.ts` L.158–185）
- 条件空 → 常にマッチ
- `conditions.tag_id` → イベントの `tagId` と一致する場合のみ
- `conditions.keyword` → `message_received` イベントのテキスト部分一致
- `conditions.score_threshold` → スコア以上

---

### 1-3. 流入パラメータのルーティング

| パラメータ | 保存先 | 用途 |
|---|---|---|
| `?ref=xxx` | `friends.ref_code`（初回のみ）+ `ref_tracking` テーブル | entry_routes 経由のタグ付与 |
| `?gclid=` | `friends.metadata.gclid` | Google 広告クリックID |
| `?fbclid=` | `friends.metadata.fbclid` | Facebook 広告クリックID |
| `?utm_source=` | `friends.metadata.utm_source` | 流入元 |
| `?utm_medium=` | `friends.metadata.utm_medium` | 流入メディア |
| `?utm_campaign=` | `friends.metadata.utm_campaign` | キャンペーン名 |

> **注意**: `utm_*` / `gclid` は `friends.metadata` (JSON) に保存されるが、タグへの自動変換ロジックは**未実装**。  
> LINE の follow webhook イベントには ref_code が含まれないため、友だち追加経路の `ref` は LIFF 経由のみ取得可能。

---

## 2. タグ分類案（タクソノミー設計）

### 2-1. 3軸タグ体系

DENBAラウンジの運用に必要なタグを以下の3軸で定義する。

#### 軸 A: 店舗軸 `store:`

| タグ名 | 意味 | 付与トリガー | 削除条件 |
|---|---|---|---|
| `store:kyodo` | 経堂店が主な来店店舗 | LIFF ref_code = 経堂専用QR | なし（店舗変更は手動） |
| `store:uraamisono` | 浦和美園店が主な来店店舗 | LIFF ref_code = 浦和美園専用QR | なし |

#### 軸 B: ライフサイクル軸 `lc:`

| タグ名 | 意味 | 付与トリガー | 削除条件 |
|---|---|---|---|
| `lc:registered` | 友だち追加直後（未予約） | webhook follow イベント | `lc:reserved` 付与時に削除 |
| `lc:form_reached` | 予約フォームページを開いた | LIFF ref_code = フォーム誘導リンク | `lc:reserved` 付与時に削除 |
| `lc:reserved` | 予約フォーム送信完了 | フォーム `on_submit_tag_id` | なし（永続保持） |
| `lc:dropoff` | Day14完了・未予約のままステップ終了 | Cron: step_status=completed かつ reservation_completed_at IS NULL | `lc:reserved` 付与時に削除 |
| `lc:revisit` | 2回目以降の予約完了 | フォーム送信（2回目以降の判定ロジックが必要） | なし |

#### 軸 C: 流入元軸 `src:`

| タグ名 | 意味 | 付与トリガー | 削除条件 |
|---|---|---|---|
| `src:article` | 記事・ブログ経由の友だち追加 | LIFF ref_code = 記事誘導リンク | なし |
| `src:popqr` | 店頭ポップQR経由 | LIFF ref_code = 店頭QR | なし |
| `src:organic` | UTM / ref なしの自然流入 | 友だち追加時に ref_code が NULL の場合 | なし |
| `src:ad_google` | Google 広告経由 | metadata.gclid が存在（現状は自動変換未実装） | なし |
| `src:ad_meta` | Meta 広告経由 | metadata.fbclid が存在（現状は自動変換未実装） | なし |

---

### 2-2. トリガー × 削除 マトリクス

| タグ | 付与タイミング | 付与方法 | 削除タイミング | 削除方法 |
|---|---|---|---|---|
| `store:kyodo` | LIFF QR読取 | entry_routes → addTagToFriend | 手動のみ | API DELETE |
| `store:uraamisono` | LIFF QR読取 | entry_routes → addTagToFriend | 手動のみ | API DELETE |
| `lc:registered` | 友だち追加 | webhook follow（要実装） | 予約完了時 | automation remove_tag |
| `lc:form_reached` | フォームページ訪問 | entry_routes（フォーム誘導ref） | 予約完了時 | automation remove_tag |
| `lc:reserved` | フォーム送信 | forms.on_submit_tag_id | なし | — |
| `lc:dropoff` | Cron（Day14後） | 新規 Cron ジョブ（要実装） | 予約完了時 | automation remove_tag |
| `src:article` | LIFF callback | entry_routes | なし | — |
| `src:popqr` | LIFF callback | entry_routes | なし | — |
| `src:organic` | 友だち追加時 | webhook follow（要実装） | なし | — |

---

## 3. 実装フィージビリティ評価

### 3-1. 現状のコードで即実現可能（DB + entry_routes 設定のみ）

| やること | 手順 | 工数 |
|---|---|---|
| `store:kyodo` / `store:uraamisono` タグを DB に作成 | UIまたは D1 INSERT | 5分 |
| 経堂・浦和美園それぞれの entry_routes レコードを作成し tag_id をセット | D1 INSERT | 10分 |
| LIFF URL に `?ref=kyodo-qr` / `?ref=uraamisono-qr` を付与して QR 作成 | LINE公式アカウント設定 | 10分 |
| `lc:reserved` タグを DB に作成し、予約フォームの `on_submit_tag_id` にセット | UIまたは D1 UPDATE | 10分 |
| `src:article` / `src:popqr` タグ + entry_routes 追加 | D1 INSERT | 10分 |

**これだけで店舗識別・予約完了・流入元の主要タグが動く。コード変更ゼロ。**

---

### 3-2. 軽微なコード追加で実現可能

#### (a) `lc:registered` — 友だち追加時に自動付与

**追加箇所**: `apps/worker/src/routes/webhook.ts` の follow イベントハンドラ  
**現状**: user_step_status UPSERT + Day0 push は実装済み。タグ付与のみ未実装。  
**追加コード例**:
```typescript
// 既存の user_step_status UPSERT の直後に追加
const registeredTag = await db
  .prepare(`SELECT id FROM tags WHERE name = 'lc:registered' LIMIT 1`)
  .first<{ id: string }>();
if (registeredTag) {
  const friend = await getFriendByLineUserId(db, userId);
  if (friend) {
    await addTagToFriend(db, friend.id, registeredTag.id);
  }
}
```
**工数**: 1時間以内

#### (b) `src:organic` — ref_code なしの自然流入を識別

**追加箇所**: 同 follow イベントハンドラ  
**判定**: `friends.ref_code IS NULL` の場合に付与  
**工数**: 30分

#### (c) UTM → `src:ad_google` / `src:ad_meta` 自動変換

**追加箇所**: `apps/worker/src/routes/liff.ts` L.327–343 の UTM 保存処理の後  
**現状**: `metadata.gclid` / `metadata.fbclid` は保存されているがタグ化されていない  
**追加コード例**:
```typescript
if (gclid) await addTagToFriend(db, friend.id, googleAdTagId);
if (fbclid) await addTagToFriend(db, friend.id, metaAdTagId);
```
**工数**: 1時間以内

---

### 3-3. 新規実装が必要（中規模）

#### (d) `lc:dropoff` — Day14完了後・未予約者の検出

**現状**: `user_step_status.step_status = 'completed'` は実装済み（Day14送信後に自動更新）。  
**不足**: `reservation_completed_at` の自動更新ロジックが未実装（`NULL` のまま）。  
**必要な実装**:
1. `lc:reserved` タグ付与と同時に `user_step_status.reservation_completed_at` を UPDATE する automation アクション（または forms.ts 側で直接 UPDATE）
2. 日次 Cron（UTC 03:00 = JST 12:00 など）で下記を実行するジョブ追加:
```sql
SELECT u.line_user_id FROM user_step_status u
JOIN friends f ON f.line_user_id = u.line_user_id
WHERE u.step_status = 'completed'
  AND u.reservation_completed_at IS NULL
  AND NOT EXISTS (
    SELECT 1 FROM friend_tags ft
    JOIN tags t ON t.id = ft.tag_id
    WHERE ft.friend_id = f.id AND t.name = 'lc:dropoff'
  )
```
**工数**: 半日

#### (e) `lc:revisit` — 2回目予約の識別

**現状**: フォーム送信は1回目・2回目を区別しない。  
**実装方法**: フォーム送信時に `lc:reserved` がすでに存在するかチェックし、存在する場合は `lc:revisit` を付与。  
**工数**: 2〜3時間

---

## 4. 優先実装ロードマップ（推奨順）

| 優先度 | タスク | 方法 | 工数 |
|---|---|---|---|
| 🔴 即日 | 店舗タグ + entry_routes 設定（店舗QR作成） | D1 操作のみ | 30分 |
| 🔴 即日 | `lc:reserved` タグ + 予約フォーム on_submit_tag_id 設定 | D1 操作のみ | 15分 |
| 🟡 今週中 | `lc:registered` をfollowで自動付与（webhook.ts 追記） | コード小追加 | 1時間 |
| 🟡 今週中 | UTM → `src:ad_google` / `src:ad_meta` 自動変換 (liff.ts追記) | コード小追加 | 1時間 |
| 🟢 来週以降 | `lc:dropoff` Cron ジョブ実装 | 新規サービス実装 | 半日 |
| 🟢 来週以降 | `lc:revisit` 判定ロジック | forms.ts 追記 | 2時間 |

---

## 5. まとめ

**現状でコード変更ゼロで動くもの**: 店舗タグ・流入元タグ・予約完了タグ（entry_routes + on_submit_tag_id の DB 設定だけ）  
**軽微なコード追加が必要**: follow時の `lc:registered` 付与、UTM → src タグ変換  
**中規模実装が必要**: `lc:dropoff`（Day14後・未予約検出 Cron）、`lc:revisit`（2回目判定）

友だちの **どこから来たか（src）** と **どの店舗（store）** は今すぐ動かせる。  
**ライフサイクル（lc）** の完全実装は段階的に進めるのが現実的。
