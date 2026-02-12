# App TDD 実装トレース（Phase1）

## 1. 参照した一次情報
- 事業構想: `Aetas事業構想.docx`
- 全体仕様: `docs/specs/01_全体_プロダクト要求仕様書.md` `docs/specs/02_全体_機能仕様書.md` `docs/specs/03_全体_技術設計書.md`
- App仕様: `docs/specs/31_App_プロダクト要求仕様書.md` `docs/specs/32_App_機能仕様書.md` `docs/specs/33_App_技術設計書.md`
- バックログ/Issue: `docs/specs/91_実装バックログ.md` `docs/specs/92_github_issues.csv`

## 2. 実装スコープ（今回）
- 対象: Phase1 / App P0
- 実装Issue:
  - `NS-APP-001` Auth/初期化フロー
  - `NS-APP-003` Region Monitoring
  - `NS-APP-004` Enter直後Ranging
  - `NS-APP-005` Store-and-Forward
  - `NS-APP-006` Sync Worker
- 関連要求:
  - `AR-001` `AR-002` `AR-003` `AR-004`
  - `PR-002` `PR-003`

## 3. TDD方針
1. 先に失敗テストを作成（`tests/*.test.js`）
2. 最小実装でgreen化（`src/app/*.js`）
3. 仕様IDとの対応を本書で固定

## 4. 実装とテストの対応
| Issue | 仕様ID | 実装 | テスト |
|---|---|---|---|
| NS-APP-001 | AR-001 / AF-001 | `src/app/auth_state.js` | `tests/auth_state.test.js` |
| NS-APP-003 | AR-001 / AF-002 | `src/app/beacon_service.js` | `tests/beacon_service.test.js` |
| NS-APP-004 | AR-002 / AF-003 | `src/app/beacon_service.js` | `tests/beacon_service.test.js` |
| NS-APP-005 | AR-003, AR-004 / AF-004 | `src/app/movement_queue.js` | `tests/movement_queue.test.js` |
| NS-APP-006 | AR-004 / AF-005 | `src/app/sync_worker.js` | `tests/sync_worker.test.js` |

## 5. 主要受入条件の反映
- `facility_id` 取得完了まで監視開始不可（`NS-APP-001`）
- Enter時に `rssi > -90` から最大RSSIのminorを採用（`NS-APP-004`）
- 先保存してから送信し、失敗時も欠落させない（`NS-APP-005`）
- 接続回復/起動/定期の3トリガで再送する（`NS-APP-006`）
- 未同期100件を欠落なく再送できる（`NS-QA-003` 関連）

## 6. 補足
- このリポジトリ環境では `flutter` / `dart` が未導入のため、Appドメイン層をNode標準テストで先に固定した。
- 実装はRepository/Worker単位のため、Flutter + Riverpod構成へ移植しやすい責務分割にしている。

## 7. Flutter移植（今回）
- 追加実装:
  - `lib/app/domain/auth_state.dart`
  - `lib/app/domain/beacon_reading.dart`
  - `lib/app/domain/beacon_service.dart`
  - `lib/app/domain/movement_log.dart`
  - `lib/app/domain/movement_transport.dart`
  - `lib/app/domain/movement_queue.dart`
  - `lib/app/domain/sync_trigger.dart`
  - `lib/app/domain/sync_options.dart`
  - `lib/app/domain/sync_queue.dart`
  - `lib/app/domain/sync_worker.dart`
  - `lib/app/domain/uuid_v7.dart`
  - `lib/app/providers/app_providers.dart`
  - `lib/nightshiftos_app.dart`
- 追加テスト:
  - `test/domain/auth_state_test.dart`
  - `test/domain/beacon_service_test.dart`
  - `test/domain/movement_queue_test.dart`
  - `test/domain/sync_worker_test.dart`
- 実行手順:
  - `flutter test`
- 注意:
  - 本環境は `flutter` 未導入のため、Flutterテストは未実行。

## 8. 未実装分のTDD拡張（今回）
- 追加対象Issue:
  - `NS-APP-002` 権限ウィザード
  - `NS-APP-007` Critical通知ハンドラ
  - `NS-APP-008` Dashboard UIモデル
  - `NS-APP-009` 手動ケア記録
  - `NS-APP-010` iOS/Androidネイティブ設定反映（要件バリデータ）
- 追加実装:
  - `lib/app/onboarding/permissions_gateway.dart`
  - `lib/app/onboarding/onboarding_wizard.dart`
  - `lib/app/notifications/critical_alert.dart`
  - `lib/app/notifications/critical_alert_notifier.dart`
  - `lib/app/notifications/alert_navigation.dart`
  - `lib/app/notifications/critical_alert_handler.dart`
  - `lib/app/dashboard/dashboard_view_model.dart`
  - `lib/app/care/care_action.dart`
  - `lib/app/care/manual_care_service.dart`
  - `lib/app/native/native_settings_validator.dart`
  - `lib/app/domain/movement_log_sink.dart`
- 追加テスト:
  - `test/onboarding/onboarding_wizard_test.dart`
  - `test/notifications/critical_alert_handler_test.dart`
  - `test/dashboard/dashboard_view_model_test.dart`
  - `test/care/manual_care_service_test.dart`
  - `test/native/native_settings_validator_test.dart`

## 9. NS-APP-010 実反映
- 追加/変更:
  - `ios/Runner/Info.plist`
    - `NSLocationAlwaysAndWhenInUseUsageDescription`
    - `NSLocationWhenInUseUsageDescription`
    - `UIBackgroundModes: location/fetch/remote-notification`
    - `BGTaskSchedulerPermittedIdentifiers`
  - `android/app/src/main/AndroidManifest.xml`
    - `BLUETOOTH_SCAN`
    - `ACCESS_BACKGROUND_LOCATION`
    - `FOREGROUND_SERVICE_LOCATION`
    - `POST_NOTIFICATIONS`
    - `VIBRATE`
- テスト:
  - `test/native/native_config_files_test.dart`

## 10. NS-APP-007 実装拡張
- 追加実装:
  - `lib/app/notifications/local_notification_gateway.dart`
  - `lib/app/notifications/alert_feedback.dart`
  - `lib/app/notifications/flutter_local_notification_gateway.dart`
  - `lib/app/notifications/system_alert_feedback.dart`
  - `lib/app/notifications/flutter_critical_alert_notifier.dart`
  - `lib/app/notifications/fcm_critical_alert_dispatcher.dart`
  - `lib/app/notifications/noop_alert_navigation.dart`
- テスト:
  - `test/notifications/flutter_critical_alert_notifier_test.dart`
  - `test/notifications/fcm_critical_alert_dispatcher_test.dart`

## 11. NS-APP-002 UI実装
- 追加実装:
  - `lib/app/onboarding/permission_handler_gateway.dart`
  - `lib/app/onboarding/onboarding_screen.dart`
  - `lib/app/onboarding/onboarding_wizard.dart`（`requestPermission`追加）
- テスト:
  - `test/onboarding/permission_handler_gateway_test.dart`
  - `test/onboarding/onboarding_screen_test.dart`

## 12. NS-APP-008 / NS-APP-009 UI実装
- 追加実装:
  - `lib/app/dashboard/dashboard_screen.dart`
  - `lib/app/care/manual_care_service.dart`（画面連携）
- テスト:
  - `test/dashboard/dashboard_screen_test.dart`

## 13. NS-APP-005 実API接続
- 追加実装:
  - `lib/app/network/auth_token_provider.dart`
  - `lib/app/network/http_movement_transport.dart`
  - `lib/app/providers/app_providers.dart`（`movementTransportProvider`の実接続）
- テスト:
  - `test/network/http_movement_transport_test.dart`

## 14. アプリ導線統合
- 追加実装:
  - `lib/app/app.dart`
  - `lib/app/routing/app_router.dart`
  - `lib/app/auth/login_screen.dart`
  - `lib/main.dart`
- テスト:
  - `test/app/app_routing_test.dart`

## 15. JWT実装とRuntimeConfig
- 追加実装:
  - `lib/app/network/secure_storage_auth_token_provider.dart`
  - `lib/app/config/runtime_config.dart`
  - `lib/app/providers/app_providers.dart`（`runtimeConfigProvider` / `authTokenProvider`）
- 追加依存:
  - `flutter_secure_storage`
- 追加テスト:
  - `test/network/secure_auth_token_provider_test.dart`
  - `test/config/runtime_config_test.dart`

## 16. Firebase/FCM起動接続
- 追加実装:
  - `lib/app/bootstrap/app_bootstrap.dart`
  - `lib/app/bootstrap/firebase_initializer.dart`
  - `lib/app/bootstrap/firebase_messaging_source.dart`
  - `lib/main.dart`（起動時bootstrap初期化）
  - `lib/app/providers/app_providers.dart`（`appBootstrapProvider`）
- 追加テスト:
  - `test/app/app_bootstrap_test.dart`

## 17. JWT保存導線 + Firebaseプロジェクト設定反映
- 追加実装:
  - `lib/app/auth/auth_session_service.dart`
  - `lib/app/auth/login_screen.dart`（token入力とセッション確立）
  - `lib/app/network/secure_storage_auth_token_provider.dart`（write/delete対応）
  - `android/settings.gradle.kts`（`com.google.gms.google-services`宣言）
  - `android/app/build.gradle.kts`（google-services plugin適用）
  - `android/app/google-services.json.example`
  - `ios/Runner/GoogleService-Info.plist.example`
  - `.gitignore`（Firebase実鍵ファイル除外）
- 追加テスト:
  - `test/auth/auth_session_service_test.dart`
  - `test/native/firebase_project_config_test.dart`

## 18. Supabase実ログインAPI連携
- 追加実装:
  - `lib/app/auth/auth_gateways.dart`
  - `lib/app/auth/supabase_auth_gateways.dart`
  - `lib/app/auth/email_password_login_use_case.dart`
  - `lib/app/auth/supabase_initializer.dart`
  - `lib/app/auth/login_screen.dart`（email/password入力 + usecase実行）
  - `lib/app/providers/app_providers.dart`（`authGateway/profileGateway/loginUseCase/supabaseClient`）
  - `lib/main.dart`（`initializeSupabaseIfConfigured` 呼び出し）
  - `lib/app/config/runtime_config.dart`（`supabaseAnonKey`追加）
  - `pubspec.yaml`（`supabase_flutter`追加）
- 追加テスト:
  - `test/auth/email_password_login_use_case_test.dart`
  - `test/native/supabase_project_config_test.dart`

## 19. NS-APP-003/007 統合補完（通知遷移実体化 + minor購読反映）
- 追加実装:
  - `lib/app/beacon/beacon_ranging_source.dart`
  - `lib/app/notifications/provider_alert_navigation.dart`
  - `lib/app/providers/app_providers.dart`
    - `beaconRangingSourceProvider`
    - `pendingAlertMinorProvider`
    - `alertNavigationProvider` を `ProviderAlertNavigation` に差し替え
  - `lib/app/routing/app_router.dart`
    - `pendingAlertMinorProvider` 監視による dashboard 誘導
    - dashboard 画面で ranging ストリーム購読し `currentMinorProvider` を更新
  - `lib/nightshiftos_app.dart`（export追加）
- 追加テスト:
  - `test/notifications/provider_alert_navigation_test.dart`
  - `test/app/app_routing_test.dart`（ranging購読更新ケース追加）

## 20. NS-APP-003 運用導線補完（業務開始/終了トグル）
- 追加実装:
  - `lib/app/domain/beacon_service.dart`（`stopMonitoring`追加）
  - `lib/app/providers/app_providers.dart`（`monitoringEnabledProvider`追加）
  - `lib/app/dashboard/dashboard_screen.dart`
    - 業務開始/終了 `SwitchListTile` 追加
    - toggle時に `beaconService.startMonitoring/stopMonitoring` を呼び出し
  - `lib/app/routing/app_router.dart`
    - `monitoringEnabledProvider` が `false` の間はranging購読を停止
- 追加テスト:
  - `test/domain/beacon_service_test.dart`（`stopMonitoring`ケース追加）
  - `test/app/app_routing_test.dart`
    - 業務開始後のみranging更新
    - ON/OFFトグルで監視開始/停止とcurrentMinorクリア

## 21. NS-APP-001 補完（起動時セッション復元）
- 追加実装:
  - `lib/app/auth/auth_gateways.dart`（`currentSession`追加）
  - `lib/app/auth/supabase_auth_gateways.dart`（既存Supabaseセッション取得）
  - `lib/app/auth/restore_session_use_case.dart`（復元ユースケース追加）
  - `lib/app/providers/app_providers.dart`（`restoreSessionUseCaseProvider`追加）
  - `lib/main.dart`（起動時にsession復元して `authStateProvider` を初期化）
  - `lib/nightshiftos_app.dart`（export追加）
- 追加テスト:
  - `test/auth/restore_session_use_case_test.dart`

## 22. NS-APP-006 実運用接続（ランタイム再送コーディネータ）
- 追加実装:
  - `lib/app/network/connectivity_status_source.dart`
    - 接続状態ソース抽象化（現状は `NoopConnectivityStatusSource`）
  - `lib/app/bootstrap/app_runtime_coordinator.dart`
    - 起動時 `onAppLaunch`
    - `false -> true` 遷移時 `onNetworkRecovered`
    - 15分周期 `onPeriodic`
  - `lib/app/providers/app_providers.dart`
    - `connectivityStatusSourceProvider`
    - `syncPeriodicIntervalProvider`
    - `appRuntimeCoordinatorProvider`
  - `lib/main.dart`
    - 起動時に `appRuntimeCoordinator.start()` を実行
- 追加テスト:
  - `test/app/app_runtime_coordinator_test.dart`

## 23. NS-APP-003/006 実プラグイン差し替え（Connectivity + Beacon）
- 追加依存:
  - `pubspec.yaml`
    - `connectivity_plus`
    - `flutter_beacon`
- 追加実装:
  - `lib/app/network/connectivity_plus_status_source.dart`
    - `connectivity_plus` の `List<ConnectivityResult>` を `bool` 接続状態へ正規化
  - `lib/app/beacon/flutter_beacon_ranging_source.dart`
    - `flutter_beacon` によるfacility major単位のranging開始
    - `RangingResult` を `List<BeaconReading>` へ変換
  - `lib/app/providers/app_providers.dart`
    - `connectivityStatusSourceProvider` を `ConnectivityPlusStatusSource` に差し替え
    - `beaconRangingSourceProvider` を `FlutterBeaconRangingSource` に差し替え
  - `lib/nightshiftos_app.dart`（export追加）
- 追加テスト:
  - `test/network/connectivity_plus_status_source_test.dart`
  - `test/beacon/flutter_beacon_ranging_source_test.dart`

## 24. NS-APP-003 実装補完（Region Monitoring enter/exit 自動記録）
- 追加実装:
  - `lib/app/beacon/beacon_monitoring_source.dart`
    - 監視イベント抽象（enter/exit）
  - `lib/app/beacon/flutter_beacon_monitoring_source.dart`
    - `flutter_beacon.monitoring` の結果を監視イベントへ変換
  - `lib/app/domain/beacon_service.dart`
    - `updateLastKnownMinor` 追加（ranging結果の保持）
  - `lib/app/providers/app_providers.dart`
    - `beaconMonitoringSourceProvider` 追加
  - `lib/app/routing/app_router.dart`
    - monitoring購読を追加し、enter/exitで `MovementLogSink.saveLog` を実行
    - rangingで更新されたminorを `BeaconService` に保持
  - `lib/nightshiftos_app.dart`（export追加）
- 追加テスト:
  - `test/beacon/flutter_beacon_monitoring_source_test.dart`
  - `test/app/app_routing_test.dart`（monitoring enter/exit -> 自動保存ケース追加）
  - `test/domain/beacon_service_test.dart`（`updateLastKnownMinor`ケース追加）
