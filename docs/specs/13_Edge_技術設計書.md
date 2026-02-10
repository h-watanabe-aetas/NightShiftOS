# Edge技術設計書（TDD）

## 1. ハードウェア構成
- MCU: Seeed XIAO ESP32C6
- Radar: MR60BHA2（60GHz）
- 通信: BLE5.0, Wi-Fi

## 2. ソフトウェア構成
| ETC-ID | モジュール | 言語/実装 | 役割 |
|---|---|---|---|
| ETC-001 | `radar_driver` | C++ | UARTフレーム受信/検証 |
| ETC-002 | `state_engine` | C++ | 状態遷移とスコアリング |
| ETC-003 | `beacon_service` | C++ | iBeacon広告制御 |
| ETC-004 | `transport_client` | C++ | MQTT/HTTPS送信 |
| ETC-005 | `retry_buffer` | C++ | リングバッファ再送 |
| ETC-006 | `provision_portal` | C++ | SoftAP設定UI |
| ETC-007 | `ota_manager` | C++ | 署名付き更新 |

## 3. タスク設計（FreeRTOS）
- Task A（高優先）: `beacon_service` 100ms周期
- Task B（高優先）: `radar_driver` 常時受信
- Task C（中優先）: `state_engine` 100ms周期
- Task D（中優先）: `transport_client` 非同期送信
- Task E（低優先）: `ota_manager` / `provision_portal`

## 4. 設定データ（NVS）
- `facility_id`
- `room_id`
- `wifi_ssid` / `wifi_pass`
- `threshold_sitting`
- `api_token`

## 5. OTA要件
- A/Bパーティション運用
- 署名検証失敗時は旧バージョン継続
- 更新履歴を `firmware_audit` に送信

## 6. 実装チェックリスト
- コンパイルフラグでデバッグログ抑制
- WDT周期設定 5秒
- メモリ使用率 70%未満維持
- LED明るさ上限 10%
