# Edge機能仕様書（FSD）

## 1. タスクアーキテクチャ
FreeRTOSで以下を並行実行する。

| タスク | 優先度 | スタック | 周期/トリガ | 役割 |
|---|---|---|---|---|
| BeaconTask | High(5) | 4KB | 100ms | iBeacon広告、WDT feed |
| RadarTask | Mid(3) | 8KB | UART受信時 | パケット解析、状態遷移 |
| NetworkTask | Low(1) | 8KB | イベント駆動 | Wi-Fi維持、送信 |
| LedTask | Low(1) | 2KB | 50ms | LEDパターン制御 |

## 2. 機能一覧
| 機能ID | 機能 | 仕様 | 関連要求 |
|---|---|---|---|
| EF-001 | Beacon広告 | UUID固定、Major/Minor可変、100ms送信 | ER-002, ER-003 |
| EF-002 | Radar UART解析 | Header/Control/Command/Tailでフレーム判定 | ER-001 |
| EF-003 | 状態遷移判定 | `SLEEP/SITTING/OUT` + デバウンス | ER-001, ER-004, ER-005 |
| EF-004 | イベント送信 | MQTT topic or HTTPS endpointへ送信 | ER-007 |
| EF-005 | 接続維持 | 非ブロッキングWi-Fi再接続 | ER-006 |
| EF-006 | NVS設定保持 | `aetas_config`へ設定保存 | ER-008 |
| EF-007 | SoftAP設定画面 | `GET /` `POST /save` `GET /scan` | ER-009 |
| EF-008 | LED状態表示 | 5パターン（SLEEP/SITTING/OUT/ERR/SETUP） | ER-012 |
| EF-009 | WDT監視 | BeaconTask停止時に5秒以内復帰 | ER-011 |

## 3. Beacon仕様（EF-001）
### 3.1 固定値
- UUID: `4fafc201-1fb5-459e-8fcc-c5c9c331914b`
- Interval: 100ms
- TxPower: -12dBm（`ESP_PWR_LVL_N12`）

### 3.2 iBeaconパケット
- Company ID: `0x004C`（Apple）
- SubType: `0x02`
- Length: `0x15`
- Major: `NVS.fac_id`
- Minor: `NVS.room_id`

## 4. Radar状態判定（EF-002/003）
### 4.1 UARTフレーム
- Header: `0x53 0x59`
- Control: `0x80`
- Command: `0x02`（呼吸）/`0x04`（体動）
- Tail: `0x54 0x43`

### 4.2 状態定義
| 状態 | 条件 | LED | 送信 |
|---|---|---|---|
| SLEEP | 呼吸受信、低体動 | Breathing | 初回遷移時 |
| SITTING | 距離40-100cmかつ体動値>th_sit | Fast Blink | 即時 |
| OUT | 5秒無信号 | Solid On | 即時 |

### 4.3 デバウンス
- OUT以外の遷移は1秒継続で確定。
- 一過性ノイズでは遷移させない。

## 5. ネットワーク仕様（EF-004/005）
### 5.1 Wi-Fi
- `WiFi.begin`後に接続待ちでブロックしない。
- 切断時はバックグラウンド再接続。

### 5.2 MQTT
- Topic: `aetas/v1/devices/{dev_uuid}/events`
- Payload:
```json
{
  "id": "uuid-v7",
  "type": "SITTING",
  "val": 85,
  "ts": 1709280000
}
```

### 5.3 再送方針
- FSD原典準拠で「古いデータ遅延送信」を避ける。
- 送信失敗時は即破棄または最新優先保持を採用。

## 6. Provisioning仕様（EF-006/007）
- 起動時にBOOT押下でSetup Mode移行。
- SoftAP: `Aetas-Setup-{MAC_LAST_4}`
- IP: `192.168.4.1`
- 保存項目:
  - SSID / Password
  - Facility ID（Major）
  - Room ID（Minor）
  - Sitting Threshold

## 7. LED仕様（EF-008）
| 状態 | パターン | PWM |
|---|---|---|
| SLEEP | 3秒周期呼吸 | 0-25-0 |
| SITTING | 高速点滅 | 25(100ms)/0(100ms) |
| OUT | 常時点灯 | 25固定 |
| Wi-Fi Error | エラー点滅 | 25(500ms)/0(500ms) |
| Setup | SOS | `... --- ...` |

## 8. 受入試験
| TEST-ID | 試験項目 | 合格条件 |
|---|---|---|
| TEST-EF-001 | Beacon視認 | nRF ConnectでMajor/Minor確認 |
| TEST-EF-002 | Beacon共存 | Wi-Fi通信中30分欠落なし |
| TEST-EF-003 | UART解析 | 生データから有効フレーム抽出 |
| TEST-EF-004 | 状態遷移 | SITTING/OUTが条件通り発火 |
| TEST-EF-005 | WDT復旧 | BeaconTask停止時に再起動 |
| TEST-EF-006 | Provisioning | 保存後再起動で設定反映 |
