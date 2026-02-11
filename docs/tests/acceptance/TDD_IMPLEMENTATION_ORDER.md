# Phase1 TDD実装着手順（Issue起点）

## 1. 前提
- 対象: Phase1 / P0 の 30 issue
- 参照:
  - `docs/specs/93_実装着手順_確定版.md`
  - `docs/tests/acceptance/phase1_traceability.csv`
- 実行コマンド:
  - 単一issue: `scripts/run_acceptance_tests.sh --issue NS-XXXX-YYY`
  - 全体: `scripts/run_acceptance_tests.sh`

## 2. RED基準（2026-02-11時点）
- 実行: `python3 -m behave docs/tests/acceptance`
- 結果: `34 scenarios error` / `0 passed`
- 理由: すべてのstepが `NotImplementedError`（仕様固定済み、実装未着手状態）

## 3. 実装順（依存を満たす順）

| Wave | Issue | 目的 | 実行コマンド |
|---|---|---|---|
| 0 | NS-PLT-001 | Event Contract v1固定 | `scripts/run_acceptance_tests.sh --issue NS-PLT-001` |
| 0 | NS-PLT-002 | UUIDv7統一 | `scripts/run_acceptance_tests.sh --issue NS-PLT-002` |
| 0 | NS-PLT-003 | 状態語彙正規化 | `scripts/run_acceptance_tests.sh --issue NS-PLT-003` |
| 1 | NS-CLD-001 | DDL初版（中核テーブル） | `scripts/run_acceptance_tests.sh --issue NS-CLD-001` |
| 1 | NS-CLD-002 | RLS/境界制御 | `scripts/run_acceptance_tests.sh --issue NS-CLD-002` |
| 1 | NS-CLD-008 | Auth/Profile土台 | `scripts/run_acceptance_tests.sh --issue NS-CLD-008` |
| 2 | NS-EDG-001 | Beacon送出土台 | `scripts/run_acceptance_tests.sh --issue NS-EDG-001` |
| 2 | NS-EDG-002 | Radarパース土台 | `scripts/run_acceptance_tests.sh --issue NS-EDG-002` |
| 2 | NS-EDG-003 | 状態遷移エンジン | `scripts/run_acceptance_tests.sh --issue NS-EDG-003` |
| 2 | NS-EDG-004 | Edge->Cloud送信 | `scripts/run_acceptance_tests.sh --issue NS-EDG-004` |
| 2 | NS-EDG-005 | 通信断耐性 | `scripts/run_acceptance_tests.sh --issue NS-EDG-005` |
| 2 | NS-EDG-006 | Provisioning保持 | `scripts/run_acceptance_tests.sh --issue NS-EDG-006` |
| 2 | NS-EDG-007 | WDT/LED復旧 | `scripts/run_acceptance_tests.sh --issue NS-EDG-007` |
| 2 | NS-APP-001 | facility_id取得ゲート | `scripts/run_acceptance_tests.sh --issue NS-APP-001` |
| 2 | NS-APP-002 | 権限ウィザード | `scripts/run_acceptance_tests.sh --issue NS-APP-002` |
| 2 | NS-APP-003 | Region監視 | `scripts/run_acceptance_tests.sh --issue NS-APP-003` |
| 2 | NS-APP-004 | Enter直後Ranging | `scripts/run_acceptance_tests.sh --issue NS-APP-004` |
| 2 | NS-APP-005 | Store-and-Forward | `scripts/run_acceptance_tests.sh --issue NS-APP-005` |
| 2 | NS-APP-006 | Sync worker | `scripts/run_acceptance_tests.sh --issue NS-APP-006` |
| 2 | NS-APP-010 | iOS/Android必須設定 | `scripts/run_acceptance_tests.sh --issue NS-APP-010` |
| 2 | NS-CLD-003 | ingest-sensor | `scripts/run_acceptance_tests.sh --issue NS-CLD-003` |
| 2 | NS-CLD-004 | ingest-movement | `scripts/run_acceptance_tests.sh --issue NS-CLD-004` |
| 3 | NS-CLD-005 | 通知トリガー | `scripts/run_acceptance_tests.sh --issue NS-CLD-005` |
| 3 | NS-CLD-006 | Realtime配信 | `scripts/run_acceptance_tests.sh --issue NS-CLD-006` |
| 3 | NS-CLD-007 | Evidence PDF | `scripts/run_acceptance_tests.sh --issue NS-CLD-007` |
| 3 | NS-APP-007 | Critical通知 | `scripts/run_acceptance_tests.sh --issue NS-APP-007` |
| 4 | NS-QA-001 | Alert loop E2E | `scripts/run_acceptance_tests.sh --issue NS-QA-001` |
| 4 | NS-QA-002 | Auto check-in E2E | `scripts/run_acceptance_tests.sh --issue NS-QA-002` |
| 4 | NS-QA-003 | Offline再送E2E | `scripts/run_acceptance_tests.sh --issue NS-QA-003` |
| 4 | NS-QA-004 | 越境拒否E2E | `scripts/run_acceptance_tests.sh --issue NS-QA-004` |

## 4. 1 issueあたりの実装手順
1. `RED`: 対象issueのみ実行し失敗を確認する。
2. `GREEN`: step実装 + 本体実装を最小変更で行い、対象issueをパスさせる。
3. `REFACTOR`: 関連層の回帰を実行する。
4. `GATE`: Wave完了時にそのWave全issueがパスしていることを確認する。

## 5. Waveごとの完了ゲート
- Wave 0: `NS-PLT-*` 全パス。
- Wave 1: `NS-CLD-001/002/008` 全パス。
- Wave 2: `NS-EDG-*` + `NS-APP-001/002/003/004/005/006/010` + `NS-CLD-003/004` 全パス。
- Wave 3: `NS-CLD-005/006/007` + `NS-APP-007` 全パス。
- Wave 4: `NS-QA-*` 全パス（MVP Exit）。
