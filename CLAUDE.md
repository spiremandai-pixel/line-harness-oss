# LINE Harness OSS - プロジェクト概要

## 構成
- Worker: apps/worker（Cloudflare Workers + Hono）
- 管理画面: apps/web（Next.js、Vercel）
- DB: Cloudflare D1（line-crm）
- パッケージマネージャ: pnpm（npx wranglerを使うこと）

## 重要なURL
- Worker: https://line-crm-worker.spire-solution.workers.dev
- 管理画面: https://line-harness-oss-web-lq7i.vercel.app
- GitHub: https://github.com/spiremandai-pixel/line-harness-oss

## よく使うコマンド
- Workerデプロイ: cd apps/worker && npx wrangler deploy
- シークレット設定: cd apps/worker && npx wrangler secret put API_KEY
- DBスキーマ適用: npx wrangler d1 execute line-crm --remote --file=../../packages/db/schema.sql
- ログ確認: npx wrangler tail line-crm-worker --format pretty

## 環境
- OS: Windows 10 / PowerShell
- コピペ: メモ帳経由で右クリック貼り付け
- API_KEY: my-secret-key-2026

## 注意事項
- pnpm wranglerではなくnpx wranglerを使う
- workerコマンドはapps/workerディレクトリで実行
- PowerShellではパイプを使ったwranglerコマンドが動かない場合がある

## LINEアカウント
- Lキテ: 未登録（管理画面から要登録）
- DENBAラウンジ【公式】: 登録済み（Channel ID: 2009660272）

## DBカラム追加済み（2026/3/31）
- friends.line_account_id
- friend_scenarios.line_account_id
- messages_log.line_account_id