# Cloud技術設計書（TDD）

## 1. 技術スタック
- DB: PostgreSQL 15（Supabase Managed）
- Functions: Deno TypeScript
- Auth: Supabase Auth
- Push: FCM/APNs

## 2. DDL設計
### 2.1 主要テーブル
1. `facilities`
2. `profiles`（`auth.users`連携）
3. `devices`
4. `sensor_events`
5. `staff_movements`
6. `care_records`

### 2.2 インデックス
- `idx_sensor_events_device_id`
- `idx_sensor_events_created_at`
- `idx_staff_movements_staff_id`
- `idx_staff_movements_created_at`

### 2.3 物理制約
- `devices`は `(facility_id, ibeacon_minor)` をUNIQUE
- `sensor_events.type` は `SLEEP/SITTING/OUT`
- `staff_movements.action` は `ENTER/EXIT`

## 3. RLS実装設計
### 3.1 有効化対象
- `profiles`
- `devices`
- `sensor_events`
- `staff_movements`

### 3.2 ヘルパー関数
```sql
CREATE OR REPLACE FUNCTION get_my_facility_id()
RETURNS uuid LANGUAGE sql SECURITY DEFINER AS $$
  SELECT facility_id FROM public.profiles WHERE id = auth.uid()
$$;
```

### 3.3 ポリシー実装
- Profiles: 自分 + 同施設閲覧
- Devices: 同施設閲覧
- Sensor Events: 同施設deviceに限定
- Staff Movements: 自分のINSERT + 同施設閲覧

## 4. Functions設計
### 4.1 ディレクトリ
```text
supabase/functions/
  _shared/
    supabaseClient.ts
    fcmClient.ts
  ingest-sensor/
  ingest-movement/
  notify-staff/
```

### 4.2 `ingest-sensor`設計
責務:
1. JSON検証
2. `devices`死活更新
3. `sensor_events`挿入
4. 危険イベント時に`notify-staff`呼び出し

### 4.3 `ingest-movement`設計
責務:
1. JWTから`auth.uid()`解決
2. バッチINSERT
3. 失敗時にエラー応答

### 4.4 `notify-staff`設計
責務:
1. 施設内`fcm_token`取得
2. 通知payload組立
3. multicast送信

## 5. Realtime設計
```sql
ALTER PUBLICATION supabase_realtime ADD TABLE sensor_events;
ALTER PUBLICATION supabase_realtime ADD TABLE staff_movements;
```
- クライアントは`channel('public:sensor_events')`等で購読。

## 6. デプロイ設計
### 6.1 Secret投入
```bash
supabase secrets set FCM_SERVICE_ACCOUNT='{"type":"service_account",...}'
```

### 6.2 Functionsデプロイ
```bash
supabase functions deploy ingest-sensor
supabase functions deploy ingest-movement
supabase functions deploy notify-staff
```

### 6.3 マイグレーション
- DDL/RLSを`supabase/migrations`で管理。

## 7. 技術試験設計
| TEST-ID | 試験 | 合格条件 |
|---|---|---|
| TEST-CTC-001 | RLS単体 | 他施設ID指定時に0件 |
| TEST-CTC-002 | ingest統合 | DB反映と関数連鎖が成功 |
| TEST-CTC-003 | 通知統合 | token存在時に送信処理完了 |
| TEST-CTC-004 | Realtime | INSERTでクライアント反映 |

## 8. 運用設計
- PITRを有効化
- 監視項目:
  - API error率
  - 通知失敗率
  - 関数タイムアウト率
