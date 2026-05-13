/**
 * Step Distribution Service
 * 毎日 JST 11:00 (UTC 02:00) に Cron Trigger から呼び出し
 * Day1/3/7/14 の対象ユーザーに step_messages を LINE Push 送信する
 */

import { LineClient } from '@line-crm/line-sdk';
import type { Message } from '@line-crm/line-sdk';

interface StepRow {
  line_user_id: string;
  day_offset: number;
  body_json: string;
  channel_access_token: string | null;
}

/**
 * ステップ配信をまとめて実行する
 * @param db   D1Database
 * @param defaultToken  env.LINE_CHANNEL_ACCESS_TOKEN（アカウント不明時のフォールバック）
 */
export async function runStepDistribution(
  db: D1Database,
  defaultToken: string,
): Promise<void> {
  // 対象抽出: 今日送るべき day_offset のレコードを JOIN で特定
  // julianday で JST 換算した日数差 = day_offset の行のみ取得
  const { results } = await db
    .prepare(
      `SELECT
         u.line_user_id,
         m.day_offset,
         m.body_json,
         la.channel_access_token
       FROM user_step_status u
       JOIN step_messages m
         ON CAST(julianday('now', '+9 hours') - julianday(u.friend_added_at, '+9 hours') AS INTEGER) = m.day_offset
       LEFT JOIN friends f
         ON f.line_user_id = u.line_user_id AND f.is_following = 1
       LEFT JOIN line_accounts la
         ON la.id = f.line_account_id AND la.is_active = 1
       WHERE u.step_status = 'active'
         AND u.reservation_completed_at IS NULL
         AND u.unsubscribed_at IS NULL
         AND (u.last_sent_day IS NULL OR u.last_sent_day < m.day_offset)
         AND m.is_active = 1
         AND m.day_offset > 0`,
    )
    .all<StepRow>();

  console.log(`runStepDistribution: ${results.length} 件の配信対象`);

  for (const row of results) {
    const token = row.channel_access_token ?? defaultToken;
    const lineClient = new LineClient(token);

    // body_json をパース
    let messages: Message[];
    try {
      const parsed = JSON.parse(row.body_json) as { messages: Message[] };
      messages = parsed.messages;
    } catch (err) {
      console.error(
        `[stepDist] body_json パース失敗 day_offset=${row.day_offset} user=${row.line_user_id}:`,
        err,
      );
      continue;
    }

    // LINE Push 送信
    try {
      await lineClient.pushMessage(row.line_user_id, messages);

      // 配信進捗 UPDATE
      await db
        .prepare(
          `UPDATE user_step_status
           SET last_sent_day = ?, updated_at = datetime('now')
           WHERE line_user_id = ?`,
        )
        .bind(row.day_offset, row.line_user_id)
        .run();

      // Day14 送信完了 → step_status = 'completed'
      if (row.day_offset === 14) {
        await db
          .prepare(
            `UPDATE user_step_status
             SET step_status = 'completed', updated_at = datetime('now')
             WHERE line_user_id = ?`,
          )
          .bind(row.line_user_id)
          .run();
        console.log(`[stepDist] Day14 完了 → step_status=completed user=${row.line_user_id}`);
      } else {
        console.log(`[stepDist] Day${row.day_offset} 送信完了 user=${row.line_user_id}`);
      }
    } catch (err) {
      // 送信失敗は log のみ・進捗は更新しない・次のユーザーへ
      console.error(
        `[stepDist] Push 失敗 day_offset=${row.day_offset} user=${row.line_user_id}:`,
        err,
      );
    }

    // 連続送信時の 50ms スリープ
    await new Promise<void>((resolve) => setTimeout(resolve, 50));
  }
}
