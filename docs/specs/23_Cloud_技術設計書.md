# Cloud技術設計書（TDD）

## 1. 技術スタック
- DB: PostgreSQL 15（Supabase Managed）
- Functions: Deno TypeScript
- Auth: Supabase Auth
- Push: FCM/APNs

## 2. 技術コンポーネント
| CTC-ID | 名称 | 責務 |
|---|---|---|
| CTC-001 | Event Persistence Contract | UUID v7/時刻/冪等キーの契約を統一 |
| CTC-002 | Sensor Ingest Pipeline | `ingest-sensor`で保存 + 通知起動 |
| CTC-003 | Movement/Care Ingest Pipeline | `ingest-movement`で行動/ケアを正規化保存 |
| CTC-004 | Tenant Guard | RLS + `auth.uid()` による施設境界強制 |
| CTC-005 | Evidence Builder | 時系列結合SQL + PDF生成 |
| CTC-006 | Immutable Audit Guard | `sensor_events`のUPDATE/DELETE禁止 |
| CTC-007 | Realtime Stream | INSERTイベントの即時配信 |
| CTC-008 | Ops Baseline | Secrets/PITR/基本監視の初期化 |

## 3. DDL設計
### 3.1 主要テーブル
1. `facilities`
2. `profiles`（`auth.users`連携）
3. `devices`
4. `sensor_events`
5. `staff_movements`
6. `care_records`

### 3.2 インデックス
- `idx_sensor_events_device_id`
- `idx_sensor_events_created_at`
- `idx_staff_movements_staff_id`
- `idx_staff_movements_created_at`
- `idx_care_records_staff_id`
- `idx_care_records_created_at`

### 3.3 物理制約
- `devices` は `(facility_id, ibeacon_minor)` をUNIQUE
- `sensor_events.type` は `SLEEP/SITTING/OUT`
- `staff_movements.action` は `ENTER/EXIT`
- `care_records.care_type` は `TOILET/POSTURE/CHECK/OTHER`
- 各イベントテーブルは `id` をUNIQUE（冪等キー）

## 4. 不変ログ設計（CTC-006）
### 4.1 運用原則
- `sensor_events` はINSERT専用とし、UPDATE/DELETEを禁止する。
- 誤記訂正は上書きせず補正イベントを追加する。

### 4.2 実装方針
```sql
REVOKE UPDATE, DELETE ON public.sensor_events FROM authenticated;
REVOKE UPDATE, DELETE ON public.sensor_events FROM service_role;
```
- 補助で`BEFORE UPDATE OR DELETE`トリガを実装し、常に例外で拒否する。

## 5. RLS実装設計（CTC-004）
### 5.1 有効化対象
- `profiles`
- `devices`
- `sensor_events`
- `staff_movements`
- `care_records`

### 5.2 ヘルパー関数
```sql
CREATE OR REPLACE FUNCTION get_my_facility_id()
RETURNS uuid LANGUAGE sql SECURITY DEFINER AS $$
  SELECT facility_id FROM public.profiles WHERE id = auth.uid()
$$;
```

### 5.3 ポリシー実装
- Profiles: 自分 + 同施設閲覧
- Devices: 同施設閲覧
- Sensor Events: 同施設deviceに限定
- Staff Movements: 自分のINSERT + 同施設閲覧
- Care Records: 自分のINSERT + 同施設閲覧

## 6. Functions設計
### 6.1 ディレクトリ
```text
supabase/functions/
  _shared/
    supabaseClient.ts
    fcmClient.ts
  ingest-sensor/
  ingest-movement/
  notify-staff/
```

### 6.2 `ingest-sensor`設計（CTC-002）
責務:
1. JSON検証（`id, device_id, type, val, timestamp`）
2. `devices`死活更新
3. `sensor_events`挿入（冪等）
4. 危険イベント（`SITTING/OUT`）時に`notify-staff`呼び出し

### 6.3 `ingest-movement`設計（CTC-003）
責務:
1. JWTから`auth.uid()`解決（payloadの`staff_id`は拒否）
2. `action=ENTER/EXIT` は `staff_movements` に保存
3. `action=CARE_*` は `care_records` に正規化保存（`CARE_TOILET/POSTURE/CHECK`を`TOILET/POSTURE/CHECK`へ変換、その他は`OTHER`。`room_no`は`minor`を文字列化）
4. `id` を冪等キーとして重複を無害化

### 6.4 `notify-staff`設計
責務:
1. 施設内`fcm_token`取得
2. 通知payload組立
3. multicast送信

## 7. Realtime設計（CTC-007）
```sql
ALTER PUBLICATION supabase_realtime ADD TABLE sensor_events;
ALTER PUBLICATION supabase_realtime ADD TABLE staff_movements;
ALTER PUBLICATION supabase_realtime ADD TABLE care_records;
```
- クライアントは`postgres_changes`で3テーブルのINSERTを購読する。

## 8. デプロイ設計（CTC-008）
### 8.1 Secret投入
```bash
supabase secrets set FCM_SERVICE_ACCOUNT='{"type":"service_account",...}'
```

### 8.2 Functionsデプロイ
```bash
supabase functions deploy ingest-sensor
supabase functions deploy ingest-movement
supabase functions deploy notify-staff
```

### 8.3 マイグレーション
- DDL/RLS/トリガを`supabase/migrations`で管理。

## 9. 技術試験設計
| TEST-ID | 試験 | 合格条件 |
|---|---|---|
| TEST-CTC-001 | RLS単体 | 他施設ID指定時に0件 |
| TEST-CTC-002 | ingest-sensor統合 | DB反映と通知連鎖が成功 |
| TEST-CTC-003 | ingest-movement統合 | ENTER/EXITとCAREが正規化保存される |
| TEST-CTC-004 | Realtime | INSERTでクライアント反映 |
| TEST-CTC-005 | 不変ログ | `sensor_events`更新/削除が拒否される |

## 10. 運用設計
- PITRを有効化
- 監視項目:
  - API error率
  - 通知失敗率
  - 関数タイムアウト率
