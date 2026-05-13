/**
 * DENBAラウンジ 店舗別予約URL設定
 *
 * ad_code=6: geo/spire計測 (LINE導線共通)
 *
 * 新店舗追加時はここにエントリを追加する。
 * migration SQL を直接書き換える必要はなく、
 * このファイルを変更して Worker を再デプロイすれば反映される。
 */
export const STORE_RESERVATION_URLS = {
  /** 浦和美園店 (store=1) */
  1: 'https://denba-4cshd.com/l_inquiry/?store=1&menu=1&ad_code=6',
  /** 経堂コルティ店 (store=2) */
  2: 'https://denba-4cshd.com/l_inquiry/?store=2&menu=1&ad_code=6',
} as const;

export type StoreId = keyof typeof STORE_RESERVATION_URLS;

/**
 * 店舗IDから予約URLを取得する。
 * 存在しない店舗IDの場合は undefined を返す。
 */
export function getReservationUrl(storeId: number): string | undefined {
  return STORE_RESERVATION_URLS[storeId as StoreId];
}
