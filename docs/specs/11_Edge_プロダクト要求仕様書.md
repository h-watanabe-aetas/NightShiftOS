# Edgeプロダクト要求仕様書（PRD）

## 1. 文書情報
- プロダクト名: NightShift Edge (Device Module)
- バージョン: 6.0（iBeacon & Radar Hybrid）
- 対象ハード: Seeed XIAO ESP32C6 + MR60BHA2

## 2. コンセプト
「止まらない灯台」
- 危険予兆（端座位/離床）を検知しCloudへ送る。
- スタッフApp向けに居室IDのBeaconを常時発信する。

## 3. 設計哲学
- Beacon First: Wi-Fi断でもBeacon送信を止めない。
- Vital Logic: 在床判定の根拠を呼吸に置く。
- Privacy by Hardware: カメラ/マイクを搭載しない。

## 4. ハード要件
### 4.1 主要コンポーネント
| 部品 | 型番 | 役割 | 備考 |
|---|---|---|---|
| MCU | XIAO ESP32C6 | 制御中枢 | RISC-V / Wi-Fi 6 / BLE5 |
| Radar | MR60BHA2 | 呼吸/体動検知 | 60GHz FMCW |
| 電源 | USB-C | 給電 | 5V/1A以上推奨 |
| LED | Onboard Yellow | 状態表示 | D15 Low Active |

### 4.2 接続要件
| XIAO Pin | 機能 | Radar Pin | 備考 |
|---|---|---|---|
| D6 | UART TX | RX | コマンド送信 |
| D7 | UART RX | TX | データ受信（115200bps） |
| 5V/GND | 電源 | 5V/GND | 共通GND |

### 4.3 設置要件
- 高さ: 床上1.0m - 1.5m
- 向き: ベッド中央または枕元方向
- 通気: ケースに通気口を設ける

## 5. プロダクト要求
| ID | 要求 | 優先 | 受入条件 |
|---|---|---|---|
| ER-001 | 3状態推定 | Must | 内部状態 `SLEEP/SITTING/OUT_OF_BED` を判定し、Cloud送信は `SLEEP/SITTING/OUT` に正規化 |
| ER-002 | Beacon常時送信 | Must | 100ms間隔で広告継続 |
| ER-003 | Beacon優先制御 | Must | Wi-Fi通信中も広告欠落なし |
| ER-004 | 端座位判定精度 | Must | 距離40-100cmかつ体動閾値超で検出 |
| ER-005 | 離床判定 | Must | 5秒無信号で`OUT`遷移 |
| ER-006 | 非ブロッキング再接続 | Must | Wi-Fi再接続処理で主要タスク停止なし |
| ER-007 | HTTPS送信（MVP）+ MQTT拡張 | Must | MVPは`ingest-sensor`へHTTPS送信、MQTTはオプション実装として切替可能 |
| ER-008 | 設定の永続化 | Must | `fac_id/room_id/ssid/pass/th_sit`をNVS保持 |
| ER-009 | SoftAP初期設定 | Should | BOOT押下で設定モード移行 |
| ER-010 | OTA更新 | Should | Wi-Fi経由で更新可能 |
| ER-011 | WDT自己復旧 | Must | ハング時5秒以内リセット |
| ER-012 | 光害抑制 | Should | LED輝度上限10% |
| ER-013 | 部屋外漏れ最小化 | Must | 隣室誤検知を抑えるTxPower調整 |

## 6. 非機能要求
- 稼働: 24時間365日連続運転
- 復旧: WDT復帰でサービス再開
- 熱設計: 長時間運転で安全温度内
- 現地運用: nRF ConnectでBeacon確認可能

## 7. 実装フェーズ（Edge）
- Step 1: Beacon単体検証（Major/Minor視認）
- Step 2: Radar統合（呼吸連動LED + Beacon同時動作）
- Step 3: Wi-Fi/HTTPS統合（通信中Beacon継続確認）
- Step 4: MQTTオプション統合（Phase 2）
