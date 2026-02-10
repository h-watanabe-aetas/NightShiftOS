# Edge機能仕様書（FSD）

## 1. 機能一覧
| 機能ID | 機能 | 詳細 | 関連要求 |
|---|---|---|---|
| EF-001 | Radarパケット解析 | UARTフレームから呼吸/体動を抽出 | ER-001 |
| EF-002 | 状態遷移判定 | 3状態ステートマシン + デバウンス | ER-001 |
| EF-003 | Beacon送信 | UUID/Major/Minor広告 | ER-002 |
| EF-004 | イベント送信 | MQTT/HTTPSでCloudへ送信 | ER-003 |
| EF-005 | ローカル再送キュー | 断線時リングバッファ保持 | ER-003 |
| EF-006 | Provisioning | SoftAP設定UI | ER-005 |
| EF-007 | OTA更新 | 署名検証つきアップデート | ER-004 |

## 2. ステートマシン
- `SLEEP`: 呼吸検知あり、体動弱
- `SITTING`: 距離40-100cm + 体動値 > 閾値
- `OUT_OF_BED`: パケット途絶5秒超

### 遷移ガード
- `SLEEP -> SITTING`: 条件成立1秒継続
- `SITTING -> SLEEP`: 低体動2秒継続
- `* -> OUT_OF_BED`: 5秒無信号で即時

## 3. メッセージ仕様
```json
{
  "event_id": "uuid-v7",
  "device_id": "dev-001",
  "facility_id": "fac-001",
  "room_id": "201",
  "event_type": "SITTING",
  "score": 0.87,
  "ts_device": "2026-02-10T02:00:00Z",
  "model_version": "edge-rule-1.2.0"
}
```

## 4. エラー処理
- UART無応答: `sensor_fault` イベント送信 + LEDエラーパターン
- ネット断: 再送キューに最大500件保持（古い順で破棄）
- 時刻未同期: `ts_quality=unsynced` を付与

## 5. 受入試験
- EF-003: Wi-Fi接続中でもBeacon広告欠落なし（30分）
- EF-002: 合成データ1000件で遷移精度>=95%
- EF-005: 60分オフライン後の再送成功率>=99%
