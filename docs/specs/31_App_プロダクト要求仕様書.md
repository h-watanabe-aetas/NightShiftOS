# Appプロダクト要求仕様書（PRD）

## 1. 文書情報
- プロダクト名: NightShift App（Staff Mobile Client）
- バージョン: 6.0（The Scanner Edition）
- 対応OS: iOS 16+ / Android 12+
- フレームワーク: Flutter

## 2. コンセプト
「ポケットの中の守護神」
- スタッフは原則アプリを操作しない。
- 入室は自動検知し、危険時だけ強通知する。

## 3. 設計哲学
- Zero UI: 最良体験は「画面を見ない運用」。
- Dark Mode Native: 夜間視認に最適化。
- Battery Conscious: GPSを使わずBeacon中心で省電力化。

## 4. ユーザーフロー
### 4.1 シフト入り
1. ログイン
2. 権限ウィザード（位置情報常時・通知）
3. 「業務開始」トグルON
4. バックグラウンド監視開始

### 4.2 業務中
1. 入室時にdidEnterRegionで自動記録
2. 危険時は高優先通知で警告
3. 必要時のみ手動ケア記録

### 4.3 業務終了
- 業務終了トグルOFFで監視停止

## 5. 要求一覧
| ID | 要求 | 優先 | 受入条件 |
|---|---|---|---|
| AR-001 | Region Monitoring | Must | UUID+MajorでENTER/EXIT自動記録 |
| AR-002 | Ranging補完 | Must | Enter時minor特定成功率を向上 |
| AR-003 | オフライン保存 | Must | 圏外でもイベント欠落0 |
| AR-004 | 自動再送 | Must | 接続回復時に未送信一括POST |
| AR-005 | 危険通知受信 | Must | high priority通知を表示 |
| AR-006 | 強通知体験 | Must | マナーモードでも気付ける強度 |
| AR-007 | 1タップ手動ケア | Must | `CARE_TOILET/CARE_POSTURE/CARE_CHECK`等を即記録 |
| AR-008 | 現在地可視化 | Should | 最寄りminorを大きく表示 |
| AR-009 | 夜勤UI最適化 | Should | ダークテーマ + 大ボタン80px以上 |
| AR-010 | iOS審査適合 | Must | 位置情報文言と用途説明を実装 |
| AR-011 | Android常駐安定化 | Must | Foreground Service要件を満たす |
| AR-012 | 低消費電力 | Must | GPS未使用、消費増2%/h以下目標 |

## 6. UI要求
### 6.1 ホーム画面
- ステータス: 監視中/ネットワーク状態
- 現在地カード: `201号室` または `移動中...`
- 手動ボタン: 3x2グリッド

### 6.2 デバッグ画面
- 周辺BeaconのMajor/Minor/RSSIを表示
- 現地設置時の検証に使用

## 7. API要求
- Endpoint: `POST /functions/v1/ingest-movement`
- 主要項目: `id, minor, action, timestamp, rssi`
- `staff_id` はpayloadに含めず、サーバ側で`auth.uid()`から確定
- オフライン再送時は`is_offline_sync=true`

## 8. 実装ロードマップ
- Week 1: Beacon検知PoC（iOS実機必須）
- Week 2: Hiveキュー + 再送
- Week 3: UI整備 + FCM統合
