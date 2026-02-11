@phase1 @p0 @e2e
Feature: Phase1 End-to-End Acceptance
  MVP成立に必要なE2E品質ゲートを定義する。

  @NS-QA-001
  Scenario: SITTING OUTから通知までE2E通過
    Given Edge App Cloudが接続された検証環境がある
    And 居室イベントSITTINGまたはOUTを発生させる
    When 通知連鎖を実行する
    Then スタッフ端末に通知が到達する
    And 監査ログに alert -> notify の連鎖が記録される

  @NS-QA-002
  Scenario: Enter Exitが時系列で記録される
    Given Beacon検知可能な実機環境がある
    When スタッフが入室して退室する
    Then ENTERとEXITが時系列順で保存される
    And タイムライン上で同一居室の対応として確認できる

  @NS-QA-003
  Scenario: 機内モード往復で欠落0を満たす
    Given Appに未送信イベントがある
    When 機内モードON/OFFを実施して同期する
    Then イベント欠落は0件である
    And 重複保存は発生しない

  @NS-QA-004
  Scenario: 他施設データを参照できない
    Given facility A と facility B のユーザーが存在する
    When facility Aユーザーでfacility Bのデータへアクセスする
    Then 参照と更新は拒否される
    And RLS拒否ログが記録される
