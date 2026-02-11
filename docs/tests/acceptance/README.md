# NightShiftOS Acceptance Tests

このディレクトリは、Phase1（MVP成立）向けの受け入れテストをGherkin形式で管理する。

## 目的
- Issueの受け入れ基準を実装前にテストとして固定する。
- 仕様（`docs/specs`）とIssue（`NS-*`）の差分を早期検知する。

## 対象
- Phase1 / P0 の実装Issueを対象とする。
- テストケースは Issue ID と紐付ける（例: `@NS-CLD-004`）。

## ファイル構成
- `phase1_platform.feature`
- `phase1_edge.feature`
- `phase1_cloud.feature`
- `phase1_app.feature`
- `phase1_e2e.feature`
- `phase1_traceability.csv`（IssueとFeatureの対応表）
- `TDD_IMPLEMENTATION_ORDER.md`（Issue起点の実装順）

## 運用ルール
- 仕様変更時は該当Issueとfeatureの両方を同時更新する。
- 各Scenarioは最低1つの正常系と1つの境界/異常系を含む。
- 受け入れテストはCI導入時に自動実行へ移行する（現時点は仕様テストとして運用）。
