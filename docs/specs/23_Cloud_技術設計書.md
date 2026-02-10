# Cloud技術設計書（TDD）

## 1. 技術スタック
- Platform: Supabase/PostgreSQL + Edge Functions
- Runtime: TypeScript (Deno/Node互換)
- Notification: FCM/APNs
- Monitoring: OpenTelemetry + Dashboard + Alerting

## 2. コンポーネント設計
| CTC-ID | コンポーネント | 実装責務 |
|---|---|---|
| CTC-001 | `ingest_edge_fn` | Edgeイベント受信/APIキー検証 |
| CTC-002 | `ingest_app_fn` | Appバッチ受信/JWT検証 |
| CTC-003 | `rule_engine` | アラート評価・エスカレーション |
| CTC-004 | `push_gateway` | FCM/APNs送信 |
| CTC-005 | `ledger_service` | 監査台帳組立 |
| CTC-006 | `report_service` | PDF/JSON生成 |
| CTC-007 | `config_service` | 施設設定管理 |

## 3. DB設計（主要）
### `events_raw`
- `event_id` PK
- `facility_id` index
- `room_id` index
- `event_type` index
- `occurred_at` index
- `payload` jsonb

### `audit_ledger`
- `ledger_id` PK
- `incident_id` index
- `observation_event_id`
- `action_event_id`
- `deviation_event_id`
- `created_at`
- `hash_signature`

## 4. データ整合性
- イベントIDはUUIDv7必須
- 同一`event_id`はupsert禁止（重複拒否）
- タイムゾーンはUTC保存、表示時のみJST変換

## 5. セキュリティ設計
- RLS: `facility_id`条件を全テーブルで強制
- 管理API: `admin`ロール限定
- エクスポート制御: 監査用途で全件ログ化

## 6. SRE設計
- アラート閾値
  - APIエラー率 >1%
  - Push失敗率 >2%
  - レポート生成 >60秒
- バックアップ: 日次フル + 15分増分
