# App技術設計書（TDD）

## 1. 技術スタック
- Flutter 3.x
- State: Riverpod
- Local DB: Hive/Isar
- Beacon: flutter_beacon
- Push: firebase_messaging + local_notifications
- Background: workmanager

## 2. モジュール設計
| ATC-ID | モジュール | 責務 |
|---|---|---|
| ATC-001 | `auth_module` | 認証とプロフィール保持 |
| ATC-002 | `beacon_module` | Region監視/Ranging |
| ATC-003 | `movement_module` | ENTER/EXIT生成 |
| ATC-004 | `sync_module` | オフライン再送 |
| ATC-005 | `notification_module` | FCM受信/ローカル通知 |
| ATC-006 | `care_module` | 手動ケア入力 |
| ATC-007 | `dashboard_module` | 稼働状態UI |

## 3. API連携
- `POST /v1/app/movements/batch`
- `POST /v1/app/care-records`
- `GET /v1/app/bootstrap`

## 4. 端末権限
### iOS
- `NSLocationAlwaysAndWhenInUseUsageDescription`
- `UIBackgroundModes`: location/fetch/remote-notification

### Android
- `BLUETOOTH_SCAN`
- `ACCESS_BACKGROUND_LOCATION`
- `FOREGROUND_SERVICE_LOCATION`

## 5. バッテリー最適化
- バックグラウンド時はRegion Monitoringのみ
- Rangingは短時間（enter直後）限定
- 不要な高頻度ポーリング禁止

## 6. テスト設計
- Unit: queue再送・重複防止・権限分岐
- Integration: 疑似BeaconでEnter/Exit
- Device: iOS/Android実機で夜間運用テスト
