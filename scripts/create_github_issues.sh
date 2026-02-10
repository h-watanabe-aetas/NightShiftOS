#!/usr/bin/env bash
set -euo pipefail

CSV_PATH="${1:-docs/specs/92_github_issues.csv}"

if ! command -v gh >/dev/null 2>&1; then
  echo "gh CLI が見つかりません。先にインストールしてください。"
  exit 1
fi

if [[ ! -f "$CSV_PATH" ]]; then
  echo "CSVが見つかりません: $CSV_PATH"
  exit 1
fi

echo "Creating issues from: $CSV_PATH"

tail -n +2 "$CSV_PATH" | while IFS=, read -r id title area priority size phase dependencies acceptance_criteria; do
  issue_title="[$id] $title"
  labels="$area,$priority,$size,$phase"

  body=$(
    cat <<EOF
## 概要
$title

## チケット情報
- ID: \`$id\`
- Area: \`$area\`
- Priority: \`$priority\`
- Size: \`$size\`
- Phase: \`$phase\`
- Dependencies: \`$dependencies\`

## 受入条件
- $acceptance_criteria

## 関連仕様
- \`docs/specs/91_実装バックログ.md\`
- \`docs/specs/90_トレーサビリティマトリクス.md\`
EOF
  )

  echo "-> $issue_title"
  gh issue create --title "$issue_title" --body "$body" --label "$labels"
done

echo "Done."
