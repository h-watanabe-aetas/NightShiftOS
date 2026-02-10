# App機能仕様書（FSD）

## 1. アーキテクチャ
### 1.1 状態管理
- `AuthState`: 認証状態、スタッフ情報、facility_id
- `BeaconState`: 現在地minor、監視状態
- `QueueState`: 未送信件数、最終同期時刻

### 1.2 ストレージ
- Hive box `logs`: movementログ
- Hive box `prefs`: 設定/キャッシュ
- `flutter_secure_storage`: 機密トークン

## 2. 機能一覧
| 機能ID | 機能名 | 仕様 | 関連要求 |
|---|---|---|---|
| AF-001 | Auth初期化 | ログイン後に`profiles.facility_id`取得 | AR-001 |
| AF-002 | Region Monitoring | UUID+Majorでenter/exit監視 | AR-001 |
| AF-003 | Temporary Ranging | Enter直後にRSSI最大minorを特定 | AR-002 |
| AF-004 | Store-and-Forward | 先保存して非同期送信 | AR-003, AR-004 |
| AF-005 | Sync Worker | 接続回復/定期/起動時に再送 | AR-004 |
| AF-006 | Critical通知処理 | FCM受信、音/バイブ、画面誘導 | AR-005, AR-006 |
| AF-007 | 手動ケアUI | 1タップCAREイベント作成 | AR-007 |
| AF-008 | ダッシュボードUI | 現在地/状態/未送信件数表示 | AR-008, AR-009 |

## 3. 詳細仕様
### 3.1 認証と初期化（AF-001）
1. Supabase Authでログイン
2. `profiles`から`facility_id, name`取得
3. `facility_id`取得完了まで監視開始不可

### 3.2 Region Monitoring（AF-002）
- UUID: `4fafc201-1fb5-459e-8fcc-c5c9c331914b`
- Major: `facility_id`
- Minor: wildcard

イベント:
- `didEnterRegion`: 短時間ranging開始 -> `ENTER`生成
- `didExitRegion`: 最終minorで`EXIT`生成（OS遅延20-30秒想定）

### 3.3 Ranging（AF-003）
- 1秒周期で取得（画面ON時）
- `rssi > -90` のみ採用
- RSSI降順で先頭minorを現在地表示

### 3.4 オフライン同期（AF-004/005）
```dart
class MovementLog {
  String id;
  String staffId;
  int minor;
  String action; // ENTER/EXIT/CARE_*
  DateTime timestamp;
  bool isSynced;
}
```
- 保存フロー:
  1. イベント発生
  2. Hiveへ保存（`isSynced=false`）
  3. 送信試行
- 再送トリガ:
  - 接続回復
  - workmanager（Android 15分）
  - iOS background fetch
  - アプリ起動時

### 3.5 通知処理（AF-006）
- Foreground: オーバーレイ + 警告音
- Background/Terminated: システム通知
- Android channel:
  - id: `critical_alert`
  - importance: max
  - sound: `alert_sound.mp3`

## 4. UI仕様
### 4.1 Onboarding
- 常時位置情報の必要性を明記
- GPS追跡しないことを明記
- 通知/Bluetooth許可を段階案内

### 4.2 Dashboard
- AppBar: スタッフ名/施設名
- Location Card: 現在地or移動中
- Quick Action Grid: 3x2
- Footer: 業務終了スライドボタン

## 5. API仕様
- `POST /functions/v1/ingest-movement`
- Header: `Authorization: Bearer <SUPABASE_JWT>`
- Body: `movements[]`

## 6. OS設定仕様
### 6.1 iOS
- `NSLocationAlwaysAndWhenInUseUsageDescription`
- `NSLocationWhenInUseUsageDescription`
- `UIBackgroundModes`: `location/fetch/remote-notification`

### 6.2 Android
- `BLUETOOTH_SCAN`
- `ACCESS_BACKGROUND_LOCATION`
- `FOREGROUND_SERVICE_LOCATION`

## 7. 受入試験
| TEST-ID | 観点 | 合格条件 |
|---|---|---|
| TEST-AF-001 | iOS入室検知 | ロック時に通知表示 |
| TEST-AF-002 | タスクキル耐性 | 背景復帰でenter取得（OS依存範囲で評価） |
| TEST-AF-003 | オフライン再送 | 100件欠落なし |
| TEST-AF-004 | 通知遅延 | 受信から表示2秒以内（P95） |
| TEST-AF-005 | 手動ケア | 1タップで記録作成 |
