#!/usr/bin/env bash
set -euo pipefail

CSV_PATH="${1:-docs/specs/92_github_issues.csv}"
MODE="${2:-upsert}" # upsert | create-only

if ! command -v gh >/dev/null 2>&1; then
  echo "gh CLI が見つかりません。先にインストールしてください。"
  exit 1
fi

if [[ ! -f "$CSV_PATH" ]]; then
  echo "CSVが見つかりません: $CSV_PATH"
  exit 1
fi

if ! gh auth status >/dev/null 2>&1; then
  echo "gh が未ログインです。'gh auth login --hostname github.com --git-protocol ssh --web' を実行してください。"
  exit 1
fi

if ! gh repo view >/dev/null 2>&1; then
  echo "GitHubリポジトリを解決できません。リポジトリ直下で実行してください。"
  exit 1
fi

if [[ "$MODE" != "upsert" && "$MODE" != "create-only" ]]; then
  echo "不正なMODEです: $MODE (upsert | create-only)"
  exit 1
fi

echo "Syncing issues from: $CSV_PATH (mode=$MODE)"

python3 - "$CSV_PATH" "$MODE" <<'PY'
import csv
import json
import re
import subprocess
import sys

csv_path = sys.argv[1]
mode = sys.argv[2]

AREA_LABELS = ["Platform", "Edge", "Cloud", "App", "Web", "QA", "SRE"]
PRIORITY_LABELS = ["P0", "P1", "P2"]
SIZE_LABELS = ["S", "M", "L", "XL"]
PHASE_LABELS = ["Phase1", "Phase2", "Phase3"]

AREA_COLORS = {
    "Platform": "0052cc",
    "Edge": "0e8a16",
    "Cloud": "1d76db",
    "App": "5319e7",
    "Web": "5319e7",
    "QA": "d93f0b",
    "SRE": "fbca04",
}
PRIORITY_COLORS = {"P0": "b60205", "P1": "d93f0b", "P2": "fbca04"}
SIZE_COLORS = {"S": "0e8a16", "M": "fbca04", "L": "d93f0b", "XL": "b60205"}
PHASE_COLORS = {"Phase1": "1d76db", "Phase2": "5319e7", "Phase3": "0052cc"}


def run(args, allow_fail=False):
    res = subprocess.run(args, text=True, capture_output=True)
    if res.returncode != 0 and not allow_fail:
        raise RuntimeError(
            f"command failed: {' '.join(args)}\nstdout:\n{res.stdout}\nstderr:\n{res.stderr}"
        )
    return res


def ensure_label(name, color, description):
    # 既存時は失敗するため無視する
    run(
        ["gh", "label", "create", name, "--color", color, "--description", description],
        allow_fail=True,
    )


def to_verb_title(title):
    t = title.strip()
    replacements = [
        ("実装", "を実装する"),
        ("作成", "を作成する"),
        ("整備", "を整備する"),
        ("導入", "を導入する"),
        ("設定", "を設定する"),
        ("定義", "を定義する"),
    ]
    for suffix, repl in replacements:
        if t.endswith(suffix):
            return t[: -len(suffix)] + repl
    if t.endswith("試験"):
        return t[: -len("試験")] + "を試験する"
    return t


def compact_condition(text, max_len=24):
    t = (text or "").strip().replace("。", "")
    if not t:
        return ""
    return t if len(t) <= max_len else t[:max_len] + "…"


def build_issue_title(row):
    ticket_id = row["id"].strip()
    raw_title = row["title"].strip()
    verb_title = to_verb_title(raw_title)
    condition = compact_condition((row.get("title_condition") or "").strip() or row.get("acceptance_criteria", ""))
    if condition:
        return f"[{ticket_id}] {verb_title}（{condition}）"
    return f"[{ticket_id}] {verb_title}"


def split_dependencies(dep):
    dep = (dep or "").strip()
    if not dep or dep == "-":
        return []
    return [x.strip() for x in re.split(r"[|,]", dep) if x.strip()]


def fmt_bullets(items):
    return "\n".join(f"- {i}" for i in items)


def area_defaults(area):
    if area == "Cloud":
        return {
            "terms": [
                "RLS＝facility境界を強制するRow Level Security",
                "ingest系Function＝Edge/AppイベントをDBに正規化保存する関数",
            ],
            "premises": [
                "Supabaseプロジェクトが作成済みである",
                "必要なSecrets（例: `FCM_SERVICE_ACCOUNT`）が投入済みまたは投入可能である",
            ],
            "error_policy": {
                "invalid": "400を返却し、エラーコードをレスポンスに含める",
                "not_found": "404を返却し、対象IDをログへ出力する",
                "external": "指数バックオフで最大3回リトライし、失敗時は監査ログを残して処理を継続/中断を明示する",
            },
            "nfr": {
                "perf": "通知連鎖を含むE2EでP95 5秒以内。単体APIはP95 500ms以内を目標。",
                "sec": "RLSで他施設データ参照不可。`auth.uid()`起点で権限判定。",
                "obs": "`request_id`, `event_id`, `facility_id`, `error_code`を構造化ログで出力。",
            },
            "impl": [
                "`supabase/migrations` にDDL/RLS/制約を追加",
                "`supabase/functions/<function-name>` に実装を追加",
                "Function単体テスト + API統合テストを追加",
            ],
        }
    if area == "Edge":
        return {
            "terms": [
                "OUT_OF_BED＝Edge内部状態、Cloud送信時はOUTへ正規化",
                "BeaconTask優先＝通信中でも100ms広告を継続する方針",
            ],
            "premises": [
                "XIAO ESP32C6 + MR60BHA2の実機または同等の検証環境がある",
                "Wi-Fi/電源断を含む試験を実施できる",
            ],
            "error_policy": {
                "invalid": "不正フレームは破棄し、処理継続する",
                "not_found": "対象設定が未ロードならデフォルト値で起動し警告ログを出す",
                "external": "送信失敗時はリングバッファへ保持し、復帰後に再送する",
            },
            "nfr": {
                "perf": "Beacon起動5秒以内、広告欠落なし（30分連続検証）。",
                "sec": "Device tokenで送信認証。設定情報はNVSのみ保持し不要露出しない。",
                "obs": "状態遷移・再送・Wi-Fi状態を時刻付きログで記録。",
            },
            "impl": [
                "FreeRTOSタスク間通信（Queue/EventGroup）を明示",
                "状態遷移のデバウンスとOUT正規化を実装",
                "実機試験手順（nRF Connect/UARTログ）を追加",
            ],
        }
    if area == "App":
        return {
            "terms": [
                "Store-and-Forward＝先保存してから非同期送信する方式",
                "Region Monitoring＝OSバックグラウンドでEnter/Exitを検知する機能",
            ],
            "premises": [
                "iOS/Android実機で権限設定を再現できる",
                "Supabase AuthでJWT取得が可能である",
            ],
            "error_policy": {
                "invalid": "不正入力はローカルに保存せず、ユーザー操作を阻害しない形で通知する",
                "not_found": "対象room/minor不明時は`移動中`として扱い、誤記録を防止する",
                "external": "通信失敗時は`isSynced=false`で保持し、復帰時に再送する",
            },
            "nfr": {
                "perf": "通知表示2秒以内（P95）、再送は起動時/接続復帰時に即実行。",
                "sec": "JWT必須。payloadに`staff_id`を含めない。",
                "obs": "Enter/Exit/Sync失敗の件数をログ/メトリクス化する。",
            },
            "impl": [
                "`lib/features/*` のRepository/Stateを更新",
                "必要に応じて`ios/` `android/`設定を更新",
                "Widget/Integrationテストを追加",
            ],
        }
    if area == "Web":
        return {
            "terms": [
                "Realtime購読＝DB INSERTを即時でUI反映する仕組み",
                "Evidence＝警告から対応までの監査証跡",
            ],
            "premises": [
                "Cloud側Realtime Publicationが有効である",
                "対象施設データがテスト環境に投入されている",
            ],
            "error_policy": {
                "invalid": "不正パラメータはバリデーションエラーとして表示",
                "not_found": "対象データなしはEmpty stateで表示",
                "external": "購読失敗時は自動再接続し、失敗継続時はUIに状態表示",
            },
            "nfr": {
                "perf": "Realtime反映は体感1秒以内。",
                "sec": "施設境界外のデータは表示不可。",
                "obs": "購読接続状態・再接続回数を計測。",
            },
            "impl": [
                "UI状態管理とRealtimeイベント処理を分離",
                "Empty/Error/Loadingの3状態を実装",
                "画面のE2Eスモークテストを追加",
            ],
        }
    if area == "QA":
        return {
            "terms": [
                "E2E＝Edge/App/Cloudを跨ぐ結合試験",
                "欠落0＝期待イベント件数と保存件数が一致する状態",
            ],
            "premises": [
                "検証対象Issueが実装完了している",
                "試験データの投入/初期化手順が定義されている",
            ],
            "error_policy": {
                "invalid": "前提未達はテスト中断し、Blockedとして記録",
                "not_found": "必要データ不足は試験環境不備として切り分ける",
                "external": "外部依存障害時は再試行1回後に失敗確定し証跡を保存",
            },
            "nfr": {
                "perf": "性能要件を満たすこと（該当Issueの閾値準拠）。",
                "sec": "認可境界の破壊試験を含める。",
                "obs": "テストログと失敗時スクリーンショット/ログIDを保存。",
            },
            "impl": [
                "テストシナリオをGiven/When/Thenで記述",
                "再現可能な手順書と期待結果を成果物化",
                "CI組込可否を判定し、不可なら理由を記録",
            ],
        }
    if area == "SRE":
        return {
            "terms": [
                "SLI＝品質指標、SLO＝達成目標",
                "PITR＝Point-in-Time Recovery",
            ],
            "premises": [
                "Cloud側ログ/メトリクス収集基盤にアクセス可能",
                "通知チャネル（Slack等）が利用可能",
            ],
            "error_policy": {
                "invalid": "不正設定は適用せず差分を明示",
                "not_found": "監視対象未登録は設定漏れとしてアラート",
                "external": "監視基盤障害時は代替確認手段を運用Runbookに記載",
            },
            "nfr": {
                "perf": "監視データ遅延を5分以内に抑える。",
                "sec": "Secretsを平文保存しない。最小権限で運用。",
                "obs": "API error率/通知失敗率/関数タイムアウト率を常時可視化。",
            },
            "impl": [
                "監視ダッシュボードとアラート閾値を定義",
                "オンコールRunbookを最小1本追加",
                "誤検知を減らすための抑制条件を設定",
            ],
        }
    # Platform default
    return {
        "terms": [
            "Event Contract＝層間で共有するイベント仕様",
            "Traceability＝PR/F/TC/TESTの追跡可能性",
        ],
        "premises": [
            "仕様正本は`docs/specs`である",
            "依存Issueが完了または同時進行である",
        ],
        "error_policy": {
            "invalid": "仕様違反入力はテストで即検知し、マージ不可とする",
            "not_found": "参照ID未定義は仕様/実装の不整合として修正する",
            "external": "外部依存障害時はローカル検証可能な代替手順を用意する",
        },
        "nfr": {
            "perf": "共通仕様は各層で追加変換なしに扱えること。",
            "sec": "認可境界を壊さない共通契約を維持。",
            "obs": "契約違反を検知するテストをCIで実行。",
        },
        "impl": [
            "契約仕様を1箇所で定義し各層へ配布",
            "変更時に`90/91/92`を同時更新",
            "契約テストを追加して破壊的変更を防止",
        ],
    }


def examples_for_issue(area, title, acceptance):
    t = title.lower()
    if "ingest-movement" in t:
        return [
            ("正常1", "JWT有効、`action=ENTER`、minor=201", "APIに1件送信", "`staff_movements`に1件保存される"),
            ("正常2", "JWT有効、`action=CARE_TOILET`", "APIに1件送信", "`care_records`に`TOILET`で保存される"),
            ("異常1", "payloadに`staff_id`を含む", "APIに送信", "`400 INVALID_PAYLOAD`を返す"),
            ("境界1", "同一`id`を2回送信", "再送する", "冪等処理で重複保存しない"),
        ]
    if "ingest-sensor" in t:
        return [
            ("正常1", "`type=SITTING`、device有効", "APIに送信", "`sensor_events`保存 + 通知処理起動"),
            ("正常2", "`type=SLEEP`", "APIに送信", "`sensor_events`保存のみ実施"),
            ("異常1", "未知の`device_id`", "APIに送信", "認証/検証エラーを返す"),
            ("境界1", "同一`id`再送", "APIに再送", "重複保存しない"),
        ]
    if "rls" in t:
        return [
            ("正常1", "同一facilityのユーザー", "対象テーブルをSELECT", "データが取得できる"),
            ("正常2", "`auth.uid()`本人のINSERT", "INSERT実行", "保存成功する"),
            ("異常1", "他facilityユーザー", "SELECT/INSERT実行", "アクセス拒否される"),
            ("境界1", "facility未設定ユーザー", "SELECT実行", "0件または権限エラー"),
        ]
    if "notify-staff" in t:
        return [
            ("正常1", "同施設にtokenあり", "SITTING通知を起動", "全tokenへ送信成功する"),
            ("正常2", "OUTイベント", "通知を起動", "高優先度通知が送信される"),
            ("異常1", "tokenなし", "通知を起動", "エラー終了せず監査ログのみ残す"),
            ("境界1", "token大量（上限近傍）", "通知を起動", "分割送信して失敗なく完了"),
        ]
    if area == "QA":
        return [
            ("正常1", "前提Issueが完了", "試験手順を実行", "期待結果を満たす"),
            ("正常2", "再試行シナリオ", "再実行", "再現性を確認できる"),
            ("異常1", "依存未完了", "試験開始", "Blockedとして記録する"),
            ("境界1", "最大件数/長時間ケース", "試験実施", "要件閾値内で完了する"),
        ]
    return [
        ("正常1", "前提条件が満たされている", "主要フローを実行", acceptance),
        ("正常2", "別入力パターン", "主要フローを実行", "同等の正しい結果を返す"),
        ("異常1", "不正入力または権限不足", "主要フローを実行", "仕様どおりにエラー処理される"),
        ("境界1", "空/null/重複/上限値", "主要フローを実行", "クラッシュせず期待動作する"),
    ]


def build_body(row):
    raw_title = row["title"].strip()
    title = to_verb_title(raw_title)
    acceptance = row["acceptance_criteria"].strip()
    area = row["area"].strip()
    deps = split_dependencies(row["dependencies"])
    defaults = area_defaults(area)
    title_condition = compact_condition((row.get("title_condition") or "").strip() or acceptance)
    title_line = f"{title}（{title_condition}）" if title_condition else title

    expected_result = (row.get("expected_result") or "").strip() or f"入力が仕様を満たすとき、{acceptance}"
    custom_boundary = (row.get("boundary_conditions") or "").strip()
    if custom_boundary:
        parts = [p.strip() for p in re.split(r"[|;]", custom_boundary) if p.strip()]
        boundary_lines = parts or [custom_boundary]
    else:
        boundary_lines = [
            "空（空配列・空文字）",
            "null（必須項目欠落）",
            "最大長/最大件数",
            "時刻境界（未来/過去/時刻ずれ）",
            "権限境界（未認証・他施設）",
            "重複（同一ID再送）",
        ]

    issue_type = (row.get("issue_type") or "").strip().lower()
    is_bug = bool(
        issue_type == "bug"
        or re.search(r"(bug|バグ|不具合|修正|fix)", raw_title, flags=re.IGNORECASE)
    )
    bug_repro_steps = (row.get("bug_repro_steps") or "").strip()
    observed_result = (row.get("observed_result") or "").strip()

    if is_bug:
        if not bug_repro_steps:
            bug_repro_steps = (
                "1. 前提環境を用意する\n"
                "2. 問題の操作を実行する\n"
                "3. 期待結果と実際結果の差分を確認する"
            )
        if not observed_result:
            observed_result = "期待と異なる結果が発生する（詳細は調査ログを追記）"
    else:
        bug_repro_steps = "N/A（機能開発チケット）"
        observed_result = "N/A（機能開発チケット）"

    in_scope = [
        f"{raw_title}に関する実装を完了し、受入条件「{acceptance}」を満たす。",
        "テストを追加して変更の正しさを自動検証できる状態にする。",
        "関連仕様（90/91）と実装差分を一致させる。",
    ]
    if deps:
        in_scope.append("依存Issueの完了を前提に統合確認を行う。")

    out_of_scope = [
        "本Issueに直接関係しない他機能の仕様変更。",
        "Phase2/Phase3タスクの先行実装。",
        "UI/UX全面改修やアーキテクチャ全面刷新。",
    ]

    terms = defaults["terms"]
    premises = defaults["premises"] + (
        [f"依存Issue: {', '.join(deps)} が完了している（または同時進行である）"] if deps else []
    )

    ac1 = f"Given 前提データと権限が正しい / When {raw_title}を実行 / Then {acceptance}"
    ac2 = "Given 境界条件（空/null/重複/権限不正） / When 同処理を実行 / Then 仕様どおりに失敗または無害化される"
    ac3 = "Given テスト環境 / When Unit・Integration・必要に応じてE2Eを実行 / Then 新規・既存テストがすべて成功する"

    examples = examples_for_issue(area, raw_title, acceptance)
    example_rows = "\n".join(
        f"| {c} | {g} | {w} | {t} |" for (c, g, w, t) in examples
    )

    error_policy = defaults["error_policy"]
    nfr = defaults["nfr"]
    impl_notes = defaults["impl"]

    bug_section = ""
    if is_bug:
        bug_section = f"""
## バグ再現情報（バグIssueのみ）
- 再現手順：
{bug_repro_steps}
- 観測された結果：
{observed_result}
"""

    return f"""## タイトル
{title_line}

## 1. 背景 / 目的
- 現状の課題：{raw_title}が未整備/不十分なため、要件の検証可能性が不足している。
- 目標（ユーザー価値/ビジネス価値）：{acceptance} を安定して達成し、MVPの成立条件に寄与する。

## 2. スコープ
### In scope（やる）
{fmt_bullets(in_scope)}
### Out of scope（やらない）
{fmt_bullets(out_of_scope)}

## 3. 用語 / 前提（必要なものだけ）
{fmt_bullets(terms)}
- 前提：
{fmt_bullets(premises)}

## 4. 期待する振る舞い（AC：観測可能に書く）
- [ ] AC1：{ac1}
- [ ] AC2：{ac2}
- [ ] AC3：{ac3}

## 5. 例（Spec by Example：テストに直結）
| ケース | Given | When | Then |
|---|---|---|---|
{example_rows}

## 6. エラー/例外ポリシー（ここが曖昧だとテストが迷子になる）
- 入力不正時：{error_policy['invalid']}
- 存在しないリソース：{error_policy['not_found']}
- 外部依存失敗時（リトライ/フォールバック/ユーザー表示）：{error_policy['external']}

## 7. 非機能（必要なものだけ）
- 性能：{nfr['perf']}
- セキュリティ/権限：{nfr['sec']}
- 監視：{nfr['obs']}

## 8. 実装メモ（任意：Howを書きたければここに隔離）
- 案、依存、リスク：
{fmt_bullets(impl_notes)}
- 期待する結果（入力Aなら出力B）：
- {expected_result}
- 境界条件：
{fmt_bullets(boundary_lines)}

## 9. 完了条件（DoD）
- [ ] Unit/Integration/E2E のどれで担保するか明記し、追加済み
- [ ] 既存テスト修正の影響範囲を確認
- [ ] リリース手順（フラグ、移行、ロールバック）必要なら記載
- [ ] 受入条件「{acceptance}」を実測またはテストで確認

{bug_section}
## メタ情報
- ID: `{row['id']}`
- Area: `{row['area']}`
- Priority: `{row['priority']}`
- Size: `{row['size']}`
- Phase: `{row['phase']}`
- Dependencies: `{row['dependencies']}`
- 関連仕様：
  - `docs/specs/91_実装バックログ.md`
  - `docs/specs/90_トレーサビリティマトリクス.md`
"""


for label in AREA_LABELS:
    ensure_label(label, AREA_COLORS.get(label, "ededed"), "Area label")
for label in PRIORITY_LABELS:
    ensure_label(label, PRIORITY_COLORS.get(label, "ededed"), "Priority label")
for label in SIZE_LABELS:
    ensure_label(label, SIZE_COLORS.get(label, "ededed"), "Size label")
for label in PHASE_LABELS:
    ensure_label(label, PHASE_COLORS.get(label, "ededed"), "Phase label")

# 全Issueを一括取得してID->番号のマップを作る（高速化）
res = run(
    [
        "gh",
        "issue",
        "list",
        "--state",
        "all",
        "--limit",
        "500",
        "--json",
        "number,title",
    ]
)
all_issues = json.loads(res.stdout)
existing_issue_number_by_id = {}
ticket_pat = re.compile(r"^\[(NS-[A-Z]+-\d{3})\]\s+")
for issue in all_issues:
    m = ticket_pat.match(issue["title"])
    if m:
        existing_issue_number_by_id[m.group(1)] = issue["number"]

updated = 0
created = 0
skipped = 0

with open(csv_path, newline="", encoding="utf-8") as f:
    reader = csv.DictReader(f)
    for row in reader:
        ticket_id = row["id"].strip()
        issue_title = build_issue_title(row)
        labels = [
            row["area"].strip(),
            row["priority"].strip(),
            row["size"].strip(),
            row["phase"].strip(),
        ]
        issue_body = build_body(row)

        number = existing_issue_number_by_id.get(ticket_id)
        if number is not None and mode == "create-only":
            print(f"skip  #{number} {issue_title} (already exists)")
            skipped += 1
            continue

        if number is not None:
            print(f"update #{number} {issue_title}")
            run(["gh", "issue", "edit", str(number), "--title", issue_title, "--body", issue_body])
            updated += 1
            continue

        print(f"create      {issue_title}")
        args = ["gh", "issue", "create", "--title", issue_title, "--body", issue_body]
        for label in labels:
            args.extend(["--label", label])
        run(args)
        created += 1

print(f"Done. created={created} updated={updated} skipped={skipped}")
PY
