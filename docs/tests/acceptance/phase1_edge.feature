@phase1 @p0 @edge
Feature: Phase1 Edge Acceptance
  Edge層のP0 Issueを満たす受け入れ条件を定義する。

  @NS-EDG-001
  Scenario: BeaconTaskが100ms広告と5秒以内起動を満たす
    Given Edgeデバイスの電源を投入する
    When BeaconTaskを起動する
    Then 5秒以内にBeaconが検知される
    And 広告間隔は100msで維持される

  @NS-EDG-002
  Scenario: Radarフレームを99%以上で抽出する
    Given UART入力に "53 59 ... 54 43" フレームを含むログがある
    When Radarフレーム解析を実行する
    Then 有効フレーム抽出率は99%以上である

  @NS-EDG-003
  Scenario: 状態遷移エンジンが仕様どおりに遷移する
    Given 呼吸・体動・無信号の入力系列がある
    When 状態遷移判定を実行する
    Then SLEEP/SITTING/OUTが仕様どおりに遷移する
    And デバウンス条件を満たさない入力では遷移しない

  @NS-EDG-004
  Scenario: ingest-sensorへHTTPS冪等送信する
    Given Edgeに有効なDevice tokenが設定されている
    When 同一idのsensorイベントを2回送信する
    Then Cloud側では1件のみ保存される
    And HTTPレスポンスは成功または重複無害化を示す

  @NS-EDG-005
  Scenario: 通信断中でも主要タスクが停止しない
    Given BeaconTaskとRadarTaskが動作中である
    When Wi-Fi接続を切断する
    Then BeaconTaskとRadarTaskは継続動作する
    And 再接続後に送信が復帰する

  @NS-EDG-006
  Scenario: Provisioning設定を再起動後も保持する
    Given fac_id room_id ssid pass th_sitを保存する
    When デバイスを再起動する
    Then 保存した設定値が復元される

  @NS-EDG-007
  Scenario: ハング時5秒以内に復旧しLEDが5パターン動作する
    Given WDT監視が有効である
    When ハングを故障注入する
    Then 5秒以内に再起動してサービス復帰する
    And LEDは5パターンの状態表示を行う
