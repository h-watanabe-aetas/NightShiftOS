@phase1 @p0 @cloud
Feature: Phase1 Cloud Acceptance
  Cloud層のP0 Issueを満たす受け入れ条件を定義する。

  @NS-CLD-001
  Scenario: MVP必須テーブルを作成する
    Given 空のDBスキーマがある
    When DDLマイグレーションを適用する
    Then facilities profiles devices sensor_events staff_movements care_records が作成される
    And 主キーと必要インデックスが作成される

  @NS-CLD-002
  Scenario: RLSヘルパーと主要ポリシーが機能する
    Given 同一facilityと他facilityのユーザーを用意する
    When get_my_facility_idとRLSポリシーでSELECT/INSERTを試行する
    Then 同一facilityのみ成功し他facilityは拒否される

  @NS-CLD-003
  Scenario: ingest-sensorが死活更新とイベント保存を行う
    Given 有効なdevice_idとsensor payloadがある
    When ingest-sensorを呼び出す
    Then devices.last_seenとstatusが更新される
    And sensor_eventsに1件保存される

  @NS-CLD-004
  Scenario: ingest-movementがENTER EXIT CAREを正規化保存する
    Given 有効なJWTとmovements配列がある
    When action=ENTER EXIT CARE_TOILET を送信する
    Then ENTER/EXITはstaff_movementsに保存される
    And CARE_TOILETはcare_recordsのTOILETとして保存される

  @NS-CLD-004 @boundary
  Scenario: ingest-movementで重複IDとstaff_id直指定を拒否または無害化する
    Given ingest-movementが稼働中である
    When 同一id再送およびpayload staff_id指定を送信する
    Then 重複は二重保存されない
    And staff_id指定は400 INVALID_PAYLOADとなる

  @NS-CLD-005
  Scenario: SITTING OUTで通知処理が起動する
    Given 同一facilityに通知tokenが登録されている
    When SITTINGまたはOUTイベントを保存する
    Then notify-staff処理が起動される
    And 送信結果が監査ログに記録される

  @NS-CLD-006
  Scenario: Realtime購読で3テーブルのINSERTが配信される
    Given sensor_events staff_movements care_recordsがpublication対象である
    When 各テーブルにINSERTする
    Then クライアント購読で3種類のイベントが受信できる

  @NS-CLD-007
  Scenario: 日次Evidence PDFを生成する
    Given 1日分のセンサー 行動 ケアデータが存在する
    When 施設と日付を指定してEvidence生成を実行する
    Then 日次PDFが出力される
    And 警告 入室 ケア 退室の時系列が復元される

  @NS-CLD-008
  Scenario: Staff Adminがログインしてプロフィール参照できる
    Given StaffとAdminのアカウントが存在する
    When 認証後にprofilesを参照する
    Then 自身と同施設データのみ参照できる
