/**
 * DENBAラウンジ リッチメニュー 再登録スクリプト
 * Node.js fetch で UTF-8 を確実に送信し、文字化けを解消する
 *
 * 使い方:
 *   cd apps/worker
 *   node ../../scripts/register-richmenu.mjs
 */

import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { dirname, join } from 'node:path';

const __dir = dirname(fileURLToPath(import.meta.url));

const WORKER_URL  = 'https://line-crm-worker.spire-solution.workers.dev';
const API_KEY     = 'my-secret-key-2026';
const ACCOUNT_ID  = 'dc316237-52ee-434e-bff1-addca7cde55e'; // DENBAラウンジ【公式】
const IMAGE_PATH  = join(__dir, '../apps/worker/assets/rich_menu_main.jpg');
const OLD_RICH_MENU_ID = 'richmenu-527a2bd3d24b793bcc9ecd377bfbd9ef';

const headers = {
  'Authorization': `Bearer ${API_KEY}`,
  'Content-Type': 'application/json',
};

// ── ユーティリティ ──────────────────────────────────────────────────────────

async function workerFetch(path, method = 'GET', body = undefined) {
  const url = `${WORKER_URL}${path}?lineAccountId=${ACCOUNT_ID}`;
  const opts = { method, headers: { ...headers } };
  if (body !== undefined) {
    opts.body = JSON.stringify(body);
  }
  const res = await fetch(url, opts);
  const text = await res.text();
  if (!res.ok) {
    throw new Error(`${method} ${path} → ${res.status}: ${text}`);
  }
  return JSON.parse(text);
}

// ── Step 1: 既存リッチメニューを削除 ─────────────────────────────────────────

console.log('▶ Step 1: 既存リッチメニューを削除...');
try {
  const r = await workerFetch(`/api/rich-menus/${OLD_RICH_MENU_ID}`, 'DELETE');
  console.log('  削除完了:', r);
} catch (e) {
  console.warn('  削除スキップ (既に削除済み?):', e.message);
}

// ── Step 2: リッチメニュー作成 ───────────────────────────────────────────────

console.log('▶ Step 2: リッチメニュー作成...');
const richMenuDef = {
  size: { width: 2500, height: 1686 },
  selected: true,
  name: 'denba_default',
  chatBarText: 'メニュー',
  areas: [
    {
      bounds: { x: 0, y: 0, width: 1250, height: 843 },
      action: { type: 'postback', data: 'payload=store_select_carousel', displayText: '予約する' },
    },
    {
      bounds: { x: 1250, y: 0, width: 1250, height: 843 },
      action: { type: 'postback', data: 'payload=denba_intro', displayText: 'DENBAとは？' },
    },
    {
      bounds: { x: 0, y: 843, width: 1250, height: 843 },
      action: { type: 'postback', data: 'payload=store_list_carousel', displayText: '店舗一覧' },
    },
    {
      bounds: { x: 1250, y: 843, width: 1250, height: 843 },
      action: { type: 'postback', data: 'payload=faq_menu', displayText: 'よくある質問' },
    },
  ],
};

const createRes = await workerFetch('/api/rich-menus', 'POST', richMenuDef);
const richMenuId = createRes.data?.richMenuId;
if (!richMenuId) throw new Error('richMenuId が取得できませんでした: ' + JSON.stringify(createRes));
console.log('  作成完了 richMenuId:', richMenuId);

// ── Step 3: 画像アップロード ──────────────────────────────────────────────────

console.log('▶ Step 3: 画像アップロード...');
const imageBytes = readFileSync(IMAGE_PATH);
const imgRes = await fetch(
  `${WORKER_URL}/api/rich-menus/${richMenuId}/image?lineAccountId=${ACCOUNT_ID}`,
  {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${API_KEY}`,
      'Content-Type': 'image/jpeg',
    },
    body: imageBytes,
  },
);
const imgText = await imgRes.text();
if (!imgRes.ok) throw new Error(`画像アップロード失敗: ${imgRes.status} ${imgText}`);
console.log('  画像アップロード完了:', imgText);

// ── Step 4: デフォルトに設定 ──────────────────────────────────────────────────

console.log('▶ Step 4: デフォルトに設定...');
const defRes = await workerFetch(`/api/rich-menus/${richMenuId}/default`, 'POST', {});
console.log('  デフォルト設定完了:', defRes);

// ── Step 5: 確認 ──────────────────────────────────────────────────────────────

console.log('▶ Step 5: 登録内容確認...');
const listRes = await workerFetch('/api/rich-menus', 'GET');
const menu = listRes.data?.find ? listRes.data.find(m => m.richMenuId === richMenuId) : listRes.data;
if (menu) {
  console.log('  chatBarText:', menu.chatBarText);
  console.log('  areas displayText:');
  (menu.areas || []).forEach((a, i) => {
    console.log(`    [${i}] ${a.action?.displayText}`);
  });
} else {
  console.log('  リスト:', JSON.stringify(listRes.data));
}

console.log('\n✅ 完了! richMenuId:', richMenuId);
