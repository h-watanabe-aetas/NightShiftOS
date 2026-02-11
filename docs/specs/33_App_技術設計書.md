# App技術設計書（TDD）

## 1. 技術スタック
- Flutter 3.x
- Riverpod + GoRouter
- Hive + flutter_secure_storage
- flutter_beacon
- firebase_messaging + flutter_local_notifications
- workmanager

## 2. ディレクトリ設計
```text
lib/
  core/
    constants/
    theme/
    network/
    storage/
  features/
    auth/
    beacon/
    logs/
    dashboard/
  app.dart
  main.dart
```

## 3. DI設計
| ATC-ID | Provider | 責務 |
|---|---|---|
| ATC-001 | `supabaseProvider` | APIクライアント供給 |
| ATC-002 | `hiveProvider` | `logs` box供給 |
| ATC-003 | `authRepositoryProvider` | 認証/プロフィール取得 |
| ATC-004 | `beaconRepositoryProvider` | Region監視とRanging |
| ATC-005 | `logRepositoryProvider` | 保存・同期 |
| ATC-006 | `authStateProvider` | 画面遷移制御 |
| ATC-007 | `beaconStateProvider` | 現在地状態管理 |

## 4. 主要モジュール実装
### 4.1 `BeaconRepository`
- `initialize()`で権限確認
- `startMonitoring(uuid, major)`で監視開始
- enter時に`_startTemporaryRanging()`を起動しminor確定

### 4.2 `LogRepository`
- `saveLog()`は先保存後に送信試行
- `_trySync()`は未同期ログをバッチ送信
- 成功時は`isSynced=true`更新または削除
- payloadには`staff_id`を含めず、認証JWTで送信者を確定
- `CARE_*`アクションはCloud側で`care_records`へ正規化される前提

### 4.3 WorkManager
- `callbackDispatcher`をentry-point登録
- 15分周期で再送処理

## 5. 画面遷移設計
### 5.1 ルート
- `/splash`
- `/login`
- `/onboarding`
- `/dashboard`

### 5.2 リダイレクト
- 未認証時は`/login`へ
- 認証済みで`/login`訪問時は`/dashboard`へ

## 6. UI技術設計
### 6.1 テーマ
- `ThemeData.dark()`ベース
- `scaffoldBackgroundColor = 0xFF121212`
- 高コントラスト配色を採用

### 6.2 Dashboard実装
- `BeaconState.currentMinor`を監視
- `AnimatedSwitcher`で部屋表示遷移
- ボタン`minimumSize`は高さ80を確保

## 7. ネイティブ設定
### 7.1 iOS
- `NSLocationAlwaysAndWhenInUseUsageDescription`
- `UIBackgroundModes`:
  - `location`
  - `fetch`
  - `remote-notification`
- `BGTaskSchedulerPermittedIdentifiers`追加

### 7.2 Android
- 必須パーミッション宣言
- WorkManager初期化Provider設定

## 8. バッテリー設計
- バックグラウンドはRegion Monitoring中心
- RangingはEnter直後の短時間のみ
- 不要な常時高頻度スキャンを禁止

## 9. 実装フェーズ
- Phase 1: Beacon Core（iOS実機）
- Phase 2: Persistence（機内モード検証）
- Phase 3: Integration（FCM受信と遷移）

## 10. 技術受入基準
| TEST-ID | 試験 | 合格条件 |
|---|---|---|
| TEST-ATC-001 | iOS背景検知 | didEnterで通知/記録 |
| TEST-ATC-002 | 再送処理 | オフラインログが復帰後反映 |
| TEST-ATC-003 | 画面遷移 | 認証状態で正しく分岐 |
| TEST-ATC-004 | FCM連携 | 通知タップで対象部屋誘導 |
