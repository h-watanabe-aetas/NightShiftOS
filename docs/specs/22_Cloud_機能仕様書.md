# Cloud機能仕様書（FSD）

## 1. 機能一覧
| 機能ID | 機能 | 説明 | 関連要求 |
|---|---|---|---|
| CF-001 | Event Ingestion | Edge/Appイベント受信と検証 | CR-001 |
| CF-002 | Alert Evaluation | ルール評価と優先度決定 | CR-002 |
| CF-003 | Notification Dispatch | FCM/APNsへの通知配信 | CR-002 |
| CF-004 | Ledger Builder | 監査台帳の時系列統合 | CR-004 |
| CF-005 | Config Manager | 設定CRUDと監査記録 | CR-005 |
| CF-006 | Report Generator | PDF/JSON証跡出力 | CR-006 |
| CF-007 | Access Control | RLS/RBAC enforcement | CR-003 |

## 2. API仕様
### 2.1 `POST /v1/edge/events`
- 認証: `X-Device-Token`
- 入力: Edgeイベント（単件）
- 挙動: 保存 -> ルール評価 -> 必要時通知

### 2.2 `POST /v1/app/movements/batch`
- 認証: `Bearer JWT`
- 入力: 行動ログ配列
- 挙動: 冪等登録 -> 対応時間再計算

### 2.3 `POST /v1/reports/evidence`
- 認証: 管理者JWT
- 入力: 施設・時間範囲・出力形式
- 出力: 署名付きレポートURL

## 3. ルール評価
- ルール例
  - `OUT_OF_BED` -> 即時Critical通知
  - `SITTING` 30秒継続 -> Warning通知
  - Critical未対応60秒 -> 再通知 + 責任者へエスカレーション

## 4. データテーブル
- `facilities`
- `devices`
- `events_raw`
- `staff_movements`
- `care_records`
- `alerts`
- `audit_ledger`
- `config_history`

## 5. 受入試験
- CF-001: 100rpsで失敗率 < 0.1%
- CF-003: Push配信成功応答率 >= 99%
- CF-007: 他施設データ参照不可を自動テストで保証
