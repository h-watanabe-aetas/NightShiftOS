# Edge技術設計書（TDD）

## 1. 実装対象
- Platform: Arduino Framework on FreeRTOS
- Target: XIAO ESP32C6
- Sensor: MR60BHA2

## 2. グローバル設定（`Config.h`）
### 2.1 定数
- `PIN_RADAR_RX=D6`
- `PIN_RADAR_TX=D7`
- `PIN_LED=D15`（Low Active）
- `PIN_BOOT=GPIO9`
- `RADAR_BAUD=115200`
- `WDT_TIMEOUT_S=5`
- `BEACON_UUID=4fafc201-1fb5-459e-8fcc-c5c9c331914b`

### 2.2 設定構造体
| フィールド | 型 | 用途 |
|---|---|---|
| `wifi_ssid` | String | 接続SSID |
| `wifi_pass` | String | 接続パスワード |
| `fac_id` | uint16_t | Beacon Major |
| `room_id` | uint16_t | Beacon Minor |
| `th_sit` | uint8_t | 端座位閾値 |
| `dev_uuid` | String | デバイス識別子 |

## 3. タスク間通信設計
### 3.1 EventGroup
| Bit | 名称 | 意味 |
|---|---|---|
| 0 | `BIT_WIFI_CONNECTED` | Wi-Fi接続済み |
| 1 | `BIT_MQTT_CONNECTED` | MQTT接続済み |
| 2 | `BIT_SETUP_MODE` | 設定モード中 |
| 3 | `BIT_RADAR_ALIVE` | レーダーハートビート有 |

### 3.2 Queue
`radarQueue` は `RadarTask -> NetworkTask` の単方向キュー。
```cpp
struct RadarEvent {
  uint8_t type; // 0:SLEEP 1:SITTING 2:OUT
  uint8_t val;
  uint32_t ts;
};
```
- 推奨サイズ: 5
- オーバーフロー時: 古いデータ破棄で最新優先

## 4. モジュール設計
| ETC-ID | モジュール | 責務 |
|---|---|---|
| ETC-001 | `BeaconTask` | BLE初期化、iBeacon広告、WDT feed |
| ETC-002 | `RadarTask` | UART受信、パケット検証、状態遷移 |
| ETC-003 | `NetworkTask` | Wi-Fi維持、MQTT publish |
| ETC-004 | `LedController` | 状態別LED制御 |
| ETC-005 | `NVSManager` | 設定のLoad/Save |
| ETC-006 | `WebPortal` | Setup UI（SoftAP） |

## 5. 詳細設計
### 5.1 BeaconTask
- iBeacon raw payloadを生成して広告開始。
- BeaconタスクのみWDTリセット権を持つ。
- 意図: Beacon停止を最優先異常として再起動する。

### 5.2 RadarTask
- 受信バイト列から`53 59 ... 54 43`フレームを組み立てる。
- `determineState()`で`SLEEP/SITTING/OUT`判定。
- 状態変化時のみ`radarQueue`へイベント投入。

### 5.3 NetworkTask
- 非ブロッキングでWi-Fi再接続。
- MQTT未接続なら`reconnectMqtt()`を試行。
- Queue受信時にJSON生成してpublish。

### 5.4 LedController
- 呼吸表現はPWMのsin波相当制御。
- 点滅はTicker/PWMタイマで非同期実装。

## 6. 永続化設計
- ライブラリ: `Preferences`
- namespace: `aetas_config`
- `loadConfig()` は起動時、`saveConfig()` は設定保存時に実行。

## 7. Provisioning設計
- Setupモード時のみWebServer起動。
- `GET /` でフォーム表示、`POST /save`で保存+再起動。
- HTMLは`PROGMEM`に埋込（SPIFFS不使用）。

## 8. ビルド設計（PlatformIO）
```toml
[env:xiao_esp32c6]
platform = espressif32
board = seeed_xiao_esp32c6
framework = arduino
monitor_speed = 115200
lib_deps =
  bblanchon/ArduinoJson @ ^7.0.0
  knolleary/PubSubClient @ ^2.8
  h2zero/NimBLE-Arduino @ ^1.4.1
build_flags =
  -D CORE_DEBUG_LEVEL=1
```

## 9. 実装順序
1. Stage 1: BeaconTask単体（UUID/Major/Minor確認）
2. Stage 2: RadarTask統合（UART解析 + LED遷移）
3. Stage 3: Network/NVS統合（送信 + 永続化）
4. Stage 4: WDT故障注入試験（意図的delayでリセット確認）

## 10. 技術受入基準
- Beacon広告はWi-Fi処理に阻害されない。
- UART不正パケットは破棄し復帰可能。
- 設定保存後の再起動でMajor/Minorが維持される。
- WDTで5秒以内に自己復旧する。
