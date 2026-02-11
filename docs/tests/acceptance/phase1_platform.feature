@phase1 @p0 @platform
Feature: Phase1 Platform Acceptance
  Platform層のP0 Issueを満たす受け入れ条件を定義する。

  @NS-PLT-001
  Scenario: Event Contract v1を配布する
    Given Event Contractの正本が未配置である
    When TC-001準拠のJSON Schemaとサンプルを追加する
    Then Edge/App/Cloudから同じSchemaを参照できる
    And Schema検証テストがCIで実行される

  @NS-PLT-001 @boundary
  Scenario: Event Contractに未定義フィールドが来た場合に失敗する
    Given Event Contract v1が配置済みである
    When 必須項目不足または未定義型のpayloadを検証する
    Then 検証は失敗しエラー理由を返す

  @NS-PLT-002
  Scenario: UUID v7採番を全層で統一する
    Given Edge/App/CloudがそれぞれIDを採番する
    When 同一テストデータで連番生成を行う
    Then すべての層でUUID v7形式が生成される
    And 時系列ソートで生成順に整列する

  @NS-PLT-002 @boundary
  Scenario: UUID形式が不正なイベントを拒否する
    Given Ingest経路が有効である
    When UUID v4など非許容フォーマットを送信する
    Then 受け入れ時にバリデーションエラーとなる

  @NS-PLT-003
  Scenario: OUT_OF_BEDをOUTへ正規化する
    Given Edge内部状態でOUT_OF_BEDが発生する
    When Cloud送信用イベントへ変換する
    Then 永続化イベントtypeはOUTとして保存される
    And トレーサビリティに変換規約が記録される

  @NS-PLT-003 @boundary
  Scenario: 未定義状態値を受け取った場合に保存しない
    Given 状態変換ガードが有効である
    When SLEEP/SITTING/OUT_OF_BED以外の状態値を処理する
    Then イベントは保存されず警告ログが出力される
