/**
 * CV（コンバージョン）計測ルート
 *
 * 予約完了・問い合わせ完了などのCVをLINEフレンドのタグとして記録する。
 *
 * 3つのエントリーポイント:
 * 1. POST /api/cv/track   — 予約システムからのWebhook / JavaScript fetch
 * 2. GET  /api/cv/pixel   — サンクスページへの1×1透過GIF埋め込み
 * 3. GET  /api/cv/link    — LINE送信用パーソナライズ予約リンク（クリック計測 + リダイレクト）
 */

import { Hono } from 'hono';
import { addTagToFriend, jstNow } from '@line-crm/db';
import type { Env } from '../index.js';

const cv = new Hono<Env>();

// CVタイプ → 付与するタグIDのマッピング
const CV_TAG_MAP: Record<string, string[]> = {
  reservation:            ['tag-cv-reserved'],
  reservation_kyodo:      ['tag-cv-reserved', 'tag-cv-reserved-kyodo'],
  reservation_uraamisono: ['tag-cv-reserved', 'tag-cv-reserved-uraamisono'],
  inquiry:                ['tag-cv-inquiry'],
};

// 1×1 透過GIF（バイナリ固定値）
const TRANSPARENT_GIF = new Uint8Array([
  0x47, 0x49, 0x46, 0x38, 0x39, 0x61, 0x01, 0x00,
  0x01, 0x00, 0x80, 0x00, 0x00, 0xff, 0xff, 0xff,
  0x00, 0x00, 0x00, 0x21, 0xf9, 0x04, 0x00, 0x00,
  0x00, 0x00, 0x00, 0x2c, 0x00, 0x00, 0x00, 0x00,
  0x01, 0x00, 0x01, 0x00, 0x00, 0x02, 0x02, 0x44,
  0x01, 0x00, 0x3b,
]);

/**
 * LINEフレンドを解決してCVタグを付与する共通処理
 *
 * 識別子の優先順:
 *   1. lineUserId  — LINE Messaging API の userId (Uxxxxxxxx)
 *   2. refCode     — 流入経路REFコード（ref_tracking から友人を検索）
 *   3. phone       — メタデータに保存された電話番号
 */
async function applyCV(
  db: D1Database,
  opts: {
    lineUserId?: string | null;
    refCode?: string | null;
    phone?: string | null;
    cvType: string;
  },
): Promise<{ success: boolean; friendId?: string; error?: string }> {
  const tags = CV_TAG_MAP[opts.cvType];
  if (!tags) {
    return { success: false, error: `Unknown cvType: ${opts.cvType}` };
  }

  let friendId: string | null = null;

  // ① LINE User ID で検索
  if (!friendId && opts.lineUserId) {
    const row = await db
      .prepare(`SELECT id FROM friends WHERE line_user_id = ? LIMIT 1`)
      .bind(opts.lineUserId)
      .first<{ id: string }>();
    if (row) friendId = row.id;
  }

  // ② REF コードで検索（最新のref_trackingエントリを使用）
  if (!friendId && opts.refCode) {
    const row = await db
      .prepare(
        `SELECT friend_id FROM ref_tracking
         WHERE ref_code = ? AND friend_id IS NOT NULL
         ORDER BY created_at DESC LIMIT 1`,
      )
      .bind(opts.refCode)
      .first<{ friend_id: string }>();
    if (row) friendId = row.friend_id;
  }

  // ③ 電話番号でメタデータ検索
  if (!friendId && opts.phone) {
    const normalized = opts.phone.replace(/[-\s]/g, '');
    const rows = await db
      .prepare(`SELECT id, metadata FROM friends WHERE metadata LIKE ? LIMIT 20`)
      .bind(`%${normalized}%`)
      .all<{ id: string; metadata: string }>();
    for (const r of rows.results) {
      try {
        const meta = JSON.parse(r.metadata || '{}') as Record<string, unknown>;
        const metaPhone = String(meta.phone || '').replace(/[-\s]/g, '');
        if (metaPhone === normalized) {
          friendId = r.id;
          break;
        }
      } catch {
        // ignore
      }
    }
  }

  if (!friendId) {
    return { success: false, error: 'Friend not found' };
  }

  // CVタグを付与
  for (const tagId of tags) {
    await addTagToFriend(db, friendId, tagId);
  }

  // CV計測ログ（conversion_events テーブルがあれば記録、なければスキップ）
  try {
    await db
      .prepare(
        `INSERT INTO conversion_events (id, friend_id, cv_type, created_at)
         VALUES (?, ?, ?, ?)`,
      )
      .bind(crypto.randomUUID(), friendId, opts.cvType, jstNow())
      .run();
  } catch {
    // テーブルが存在しない場合は無視（将来の拡張用）
  }

  return { success: true, friendId };
}

// ─────────────────────────────────────────────
// POST /api/cv/track
//
// 予約システム・フォームシステムからのWebhook受信
//
// Body (JSON):
//   lineUserId  — LINE user ID (Uxxxxxxxx)  ※いずれか1つ必須
//   refCode     — 流入REFコード
//   phone       — 電話番号（メタデータ照合）
//   cvType      — "reservation" | "reservation_kyodo" | "reservation_uraamisono" | "inquiry"
//   store       — (optional) "kyodo" | "uraamisono"  cvTypeの補完用
// ─────────────────────────────────────────────
cv.post('/api/cv/track', async (c) => {
  try {
    const body = await c.req.json<{
      lineUserId?: string;
      refCode?: string;
      phone?: string;
      cvType?: string;
      store?: string;
    }>();

    if (!body.cvType) {
      return c.json({ success: false, error: 'cvType is required' }, 400);
    }

    // store が指定されている場合 cvType を補完
    let cvType = body.cvType;
    if (body.store && cvType === 'reservation') {
      if (body.store === 'kyodo') cvType = 'reservation_kyodo';
      else if (body.store === 'uraamisono') cvType = 'reservation_uraamisono';
    }

    const result = await applyCV(c.env.DB, {
      lineUserId: body.lineUserId,
      refCode: body.refCode,
      phone: body.phone,
      cvType,
    });

    if (!result.success) {
      return c.json({ success: false, error: result.error }, 404);
    }

    return c.json({ success: true, data: { friendId: result.friendId, cvType } });
  } catch (err) {
    console.error('POST /api/cv/track error:', err);
    return c.json({ success: false, error: 'Internal server error' }, 500);
  }
});

// ─────────────────────────────────────────────
// GET /api/cv/pixel
//
// サンクスページに埋め込む1×1透過GIF
//
// Query params:
//   uid   — LINE user ID (Uxxxxxxxx)
//   ref   — 流入REFコード
//   phone — 電話番号
//   type  — cvType (省略時 "reservation")
//   store — "kyodo" | "uraamisono"
//
// 使用例 (HTMLに埋め込む):
//   <img src="https://line-crm-worker.spire-solution.workers.dev/api/cv/pixel?uid=Uxxxxxxxx&type=reservation_kyodo" width="1" height="1" style="display:none">
// ─────────────────────────────────────────────
cv.get('/api/cv/pixel', async (c) => {
  const uid   = c.req.query('uid');
  const ref   = c.req.query('ref');
  const phone = c.req.query('phone');
  const store = c.req.query('store');
  let cvType  = c.req.query('type') || 'reservation';

  if (store && cvType === 'reservation') {
    if (store === 'kyodo') cvType = 'reservation_kyodo';
    else if (store === 'uraamisono') cvType = 'reservation_uraamisono';
  }

  // 非同期でCV記録（失敗してもピクセルは返す）
  if (uid || ref || phone) {
    applyCV(c.env.DB, { lineUserId: uid, refCode: ref, phone, cvType }).catch((e) =>
      console.error('cv/pixel applyCV error:', e),
    );
  }

  return new Response(TRANSPARENT_GIF, {
    headers: {
      'Content-Type': 'image/gif',
      'Cache-Control': 'no-store, no-cache, must-revalidate',
      'Pragma': 'no-cache',
    },
  });
});

// ─────────────────────────────────────────────
// GET /api/cv/link
//
// LINE送信用パーソナライズ予約リンク
//
// Query params:
//   uid      — LINE user ID (Uxxxxxxxx) ※必須
//   store    — "kyodo" | "uraamisono"
//   redirect — リダイレクト先URL（実際の予約ページ）
//
// 使用例:
//   LINE自動返信メッセージに以下URLを含める:
//   https://...workers.dev/api/cv/link?uid=Uxxxxxxxx&store=kyodo&redirect=https://booking.jp/denba
//
//   ユーザーがタップ → クリックを記録（tag: cv:booking_clicked）→ 予約ページへリダイレクト
// ─────────────────────────────────────────────
cv.get('/api/cv/link', async (c) => {
  const uid      = c.req.query('uid');
  const store    = c.req.query('store');
  const redirect = c.req.query('redirect');

  if (!redirect) {
    return c.json({ success: false, error: 'redirect parameter is required' }, 400);
  }

  // クリック計測（非同期、失敗してもリダイレクトは続行）
  if (uid) {
    const clickTag = store === 'kyodo'
      ? 'tag-cv-click-kyodo'
      : store === 'uraamisono'
        ? 'tag-cv-click-uraamisono'
        : 'tag-cv-click';

    // クリックタグが存在する場合のみ付与（INSERT OR IGNOREでエラー防止）
    (async () => {
      try {
        const friend = await c.env.DB
          .prepare(`SELECT id FROM friends WHERE line_user_id = ? LIMIT 1`)
          .bind(uid)
          .first<{ id: string }>();
        if (friend) {
          // cv:booking_clicked ログ（cv_events相当）
          await c.env.DB
            .prepare(
              `INSERT OR IGNORE INTO ref_tracking (id, ref_code, friend_id, source_url, created_at)
               VALUES (?, ?, ?, ?, ?)`,
            )
            .bind(
              crypto.randomUUID(),
              `cv_link_click_${store || 'unknown'}`,
              friend.id,
              redirect,
              jstNow(),
            )
            .run();
        }
      } catch (e) {
        console.error('cv/link click log error:', e);
      }
    })();
  }

  // 実際の予約ページへリダイレクト
  return c.redirect(redirect, 302);
});

export { cv };
