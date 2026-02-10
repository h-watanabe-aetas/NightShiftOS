# App機能仕様書（FSD）

## 1. 機能一覧
| 機能ID | 機能 | 内容 | 関連要求 |
|---|---|---|---|
| AF-001 | 認証/初期化 | ログインと施設情報同期 | AR-001 |
| AF-002 | Beacon領域監視 | Enter/Exitトリガ取得 | AR-001 |
| AF-003 | Ranging補助 | 近接Minor推定で部屋特定 | AR-001 |
| AF-004 | オフラインキュー | 未送信ログの保持と再送 | AR-003 |
| AF-005 | 通知処理 | 重要通知の受信/表示/誘導 | AR-002 |
| AF-006 | 手動ケア入力 | 1タップ記録（TOILET等） | AR-004 |
| AF-007 | 稼働ステータスUI | 監視中/未同期件数の表示 | AR-005 |

## 2. 監視フロー
1. 業務開始トグルON
2. UUID + facility majorでRegion Monitoring開始
3. `didEnterRegion` 発火時に短時間Rangingでminor推定
4. `ENTER` イベント保存/送信
5. `didExitRegion` で `EXIT` 保存/送信

## 3. ローカルデータモデル
```json
{
  "id": "uuid-v7",
  "staff_id": "stf-001",
  "facility_id": "fac-001",
  "minor": 201,
  "action": "ENTER",
  "occurred_at": "2026-02-10T02:00:10Z",
  "synced": false,
  "retry_count": 0
}
```

## 4. 通知仕様
- channel: `critical_alert`
- 優先度: highest
- タップ時遷移: 該当居室の詳細カードへフォーカス

## 5. 受入試験
- AF-002: バックグラウンドでEnter/Exit 95%以上検知
- AF-004: 100件オフライン蓄積後、再送欠落0
- AF-005: 通知受信から表示まで2秒以内（P95）
