# Cloud機能仕様書（FSD）

## 1. 機能一覧
| 機能ID | 機能名 | 入力 | 出力 | 関連要求 |
|---|---|---|---|---|
| CF-001 | Schema管理 | DDL/RLS | 施設分離DB | CR-001, CR-003 |
| CF-002 | `ingest-sensor` | Edgeイベント | `sensor_events`登録 | CR-001, CR-002 |
| CF-003 | `ingest-movement` | Appバッチ | `staff_movements`登録 | CR-001, CR-007 |
| CF-004 | `notify-staff` | 危険イベント | FCM/APNs送信 | CR-002 |
| CF-005 | Realtime配信 | INSERTイベント | ダッシュボード更新 | CR-005 |
| CF-006 | Evidence生成 | 日付/施設指定 | PDFレポート | CR-006 |
| CF-007 | アクセス制御 | JWT/Auth UID | 施設内データのみ返却 | CR-003 |

## 2. DB機能仕様
### 2.1 共通要件
- 文字コード: UTF-8
- 時刻: UTC保存（表示時にJST変換）
- 主キー: uuid（v7推奨）

### 2.2 テーブル定義（機能観点）
| テーブル | 主用途 | 主要カラム |
|---|---|---|
| `facilities` | 施設マスタ | `id,name,tier` |
| `profiles` | スタッフ管理 | `id,facility_id,name,fcm_token,role` |
| `devices` | デバイス管理 | `id,facility_id,room_no,ibeacon_minor,status,last_seen,settings` |
| `sensor_events` | センサー事実ログ | `id,device_id,type,val,created_at` |
| `staff_movements` | 入退室ログ | `id,staff_id,ibeacon_minor,action,is_manual,is_synced,created_at` |
| `care_records` | ケアログ | `id,staff_id,room_no,care_type,created_at` |

## 3. RLS機能仕様
### 3.1 ヘルパー関数
`get_my_facility_id()` を `auth.uid()` 起点で定義する。

### 3.2 ポリシー
| 対象 | 操作 | 条件 |
|---|---|---|
| `profiles` | SELECT | `id = auth.uid()` または同一facility |
| `devices` | SELECT | `facility_id = get_my_facility_id()` |
| `sensor_events` | SELECT | 同一facilityのdevice経由のみ |
| `staff_movements` | INSERT | `auth.uid() = staff_id` |
| `staff_movements` | SELECT | 同一facilityのstaffのみ |

## 4. Edge Functions仕様
### 4.1 `ingest-sensor`
- URL: `POST /functions/v1/ingest-sensor`
- 入力:
```json
{
  "id": "uuid-v7",
  "device_id": "uuid",
  "type": "SITTING",
  "val": { "dist": 0.8 }
}
```
- 処理:
  1. Device検証
  2. `devices`の`status,last_seen`更新
  3. `sensor_events`登録
  4. `type in (SITTING, OUT)`なら`notify-staff`起動

### 4.2 `ingest-movement`
- URL: `POST /functions/v1/ingest-movement`
- 認証: User JWT
- 入力: `movements[]`
- 処理:
  1. `auth.uid()`でstaff確定
  2. バッチINSERT
  3. 任意で`EXIT`時滞在時間計算

### 4.3 `notify-staff`
- 入力: `facility_id, room_no, type`
- 処理:
  1. `profiles.fcm_token`を施設単位で取得
  2. 通知payload生成
  3. FCM/APNsへマルチキャスト

## 5. Realtime仕様
- Publication対象: `sensor_events`, `staff_movements`
- クライアントは`postgres_changes INSERT`を購読
- 受信時にタイムラインストアを更新

## 6. レポート生成仕様
### 6.1 目的
センサーイベントとスタッフ行動を時系列合成し、監査説明に使える形式で出力する。

### 6.2 集計要件
- 対象: 施設 + 日付
- 並び: 発生時刻昇順
- サマリ:
  - アラート総数
  - 平均対応時間
- 明細:
  - `[警告]` `SITTING/OUT`
  - `[入室]` `ENTER`
  - `[ケア]` `care_type`
  - `[退室]` `EXIT`

## 7. 初期セットアップ機能
1. DDL/RLSをSQL Editorで実行
2. Auth Email Providerを有効化
3. `FCM_SERVICE_ACCOUNT`をsecret登録
4. 関数をdeploy

## 8. 受入試験
| TEST-ID | 観点 | 合格条件 |
|---|---|---|
| TEST-CF-001 | Ingest | `curl`で登録成功 |
| TEST-CF-002 | Alert | `SITTING`登録で通知処理起動 |
| TEST-CF-003 | RLS | 他施設データが不可視 |
| TEST-CF-004 | Realtime | INSERT直後に画面反映 |
| TEST-CF-005 | PDF | 指定日レポート出力成功 |
