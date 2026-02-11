@phase1 @p0 @app
Feature: Phase1 App Acceptance
  App層のP0 Issueを満たす受け入れ条件を定義する。

  @NS-APP-001
  Scenario: facility_id取得完了まで監視を開始しない
    Given ユーザーがログイン済みである
    When profilesからfacility_id取得前に監視開始を試行する
    Then 監視は開始されない
    And facility_id取得後にのみ監視開始できる

  @NS-APP-002
  Scenario: 権限ウィザードで必須導線を提供する
    Given 初回起動状態である
    When 権限ウィザードを表示する
    Then 位置情報常時 通知 Bluetooth の順で許可導線が表示される
    And 許可未完了時は業務開始トグルをONにできない

  @NS-APP-003
  Scenario: Region MonitoringでEnter Exitイベントを作成する
    Given UUID Majorが正しく設定されている
    When didEnterRegionとdidExitRegionが発火する
    Then ENTER/EXITイベントがローカルキューに保存される

  @NS-APP-004
  Scenario: Enter直後のRangingでRSSI最大minorを反映する
    Given Enter直後に複数Beaconが観測される
    When 一時Rangingを実行する
    Then RSSI最大minorがENTERイベントに設定される

  @NS-APP-005
  Scenario: Store-and-Forwardで欠落なく送信する
    Given オフライン状態でイベントを作成する
    When ネットワーク復帰後に同期処理を実行する
    Then 保存済みイベントは欠落なく送信される
    And 送信成功イベントはisSynced=trueになる

  @NS-APP-006
  Scenario: Sync Workerが3トリガーで再送する
    Given 未同期イベントが存在する
    When 接続回復 定期実行 起動時の各トリガーを発火する
    Then 各トリガーで再送が実行される

  @NS-APP-007
  Scenario: Critical通知を2秒以内に表示し音バイブを鳴らす
    Given 高優先度通知を受信する
    When 通知ハンドラを実行する
    Then 2秒以内に通知が表示される
    And 音とバイブが作動する

  @NS-APP-010
  Scenario: iOS Androidの必須設定を満たす
    Given プラットフォーム設定ファイルが存在する
    When マニフェストとplistを検証する
    Then 必須manifest plist background設定がすべて存在する
