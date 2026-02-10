# Cloudプロダクト要求仕様書（PRD）

## 1. 文書情報
- プロダクト名: NightShift Cloud (Backend & Dashboard)
- バージョン: 6.0（The Judge Edition）
- プラットフォーム: Supabase（PostgreSQL / Edge Functions / Realtime）

## 2. コンセプト
「説明責任の自動化」
- Edgeの危険予兆とAppの対応行動を時系列統合する。
- 実地指導・事故時に提出可能な証跡を自動生成する。

## 3. 設計哲学
- Serverless First: 運用負荷を最小化する。
- Secure by Design: RLSで施設境界を強制する。
- Realtime First: 管理画面は更新操作なしで追従する。

## 4. 要求一覧
| ID | 要求 | 優先 | 受入条件 |
|---|---|---|---|
| CR-001 | センサー/行動イベント受信 | Must | API受信後DB登録成功率>=99.9% |
| CR-002 | 危険イベント通知 | Must | `SITTING/OUT`で通知ロジックが必ず起動 |
| CR-003 | 施設単位データ分離 | Must | RLS侵入試験で越境0件 |
| CR-004 | 不変ログ保持 | Must | `sensor_events`の改変不可運用 |
| CR-005 | リアルタイム表示 | Must | INSERTイベントを即時UI反映 |
| CR-006 | 監査レポート出力 | Must | 日次PDFをダウンロード可能 |
| CR-007 | 認証統合 | Must | Staff/AdminをSupabase Authで管理 |
| CR-008 | デバイス死活監視 | Must | `devices.last_seen/status`更新 |
| CR-009 | 運用可能なバックアップ | Should | PITR有効化 |
| CR-010 | 将来拡張可能なデータ構造 | Should | UUID v7前提の時系列設計 |

## 5. データ要件
### 5.1 マスタ
- `facilities`
- `devices`
- `profiles`

### 5.2 トランザクション
- `sensor_events`（事実ログ）
- `staff_movements`（行動ログ）
- `care_records`（ケア記録）

## 6. ダッシュボード要求
### 6.1 タイムライン
- X軸: 現在から過去12時間
- Y軸: 部屋番号
- レイヤー:
  - Alert Layer（黄: SITTING、赤: OUT）
  - Staff Layer（緑: ENTER-EXIT）
  - Action Icon（TOILET等）

### 6.2 レポート
- ヘッダ: 施設名、日付
- サマリ: アラート回数、平均対応時間
- 明細: 発生 -> 入室 -> ケア -> 退室

## 7. セキュリティ要求
- Staff/Admin: Email/Password認証
- Edge: MVPは簡易トークン、将来はデバイス個別JWT
- すべての業務テーブルでRLSを有効化

## 8. ロードマップ（Cloud）
- Week 1: Schema + Ingest
- Week 2: Notification + Realtime
- Week 3: Dashboard + PDF

## 9. 運用要件
- ログ保持: MVPは無期限（将来はライフサイクル設定）
- バックアップ: Supabase PITRを有効化
