#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REQ_FILE="$ROOT_DIR/tests/acceptance/requirements.txt"
FEATURE_DIR="$ROOT_DIR/docs/tests/acceptance"
INSTALL="${INSTALL_DEPS:-0}"
ISSUE_TAG=""
BEHAVE_ARGS=()

usage() {
  cat <<'EOF'
Usage:
  scripts/run_acceptance_tests.sh [options] [-- behave_args...]

Options:
  --install-deps         Install test dependencies before running.
  --issue NS-XXXX-YYY    Run only scenarios tagged with this issue id.
  -h, --help             Show this help.

Examples:
  scripts/run_acceptance_tests.sh
  scripts/run_acceptance_tests.sh --issue NS-PLT-001
  scripts/run_acceptance_tests.sh --install-deps --issue NS-CLD-004
  scripts/run_acceptance_tests.sh -- --tags=@phase1 --tags=@cloud
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --install-deps)
      INSTALL="1"
      shift
      ;;
    --issue)
      if [[ $# -lt 2 ]]; then
        echo "error: --issue requires a value (example: NS-PLT-001)" >&2
        exit 2
      fi
      ISSUE_TAG="$2"
      shift 2
      ;;
    --)
      shift
      BEHAVE_ARGS+=("$@")
      break
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      BEHAVE_ARGS+=("$1")
      shift
      ;;
  esac
done

if [[ "$INSTALL" == "1" ]]; then
  python3 -m pip install -r "$REQ_FILE"
fi

if [[ -n "$ISSUE_TAG" ]]; then
  if [[ "$ISSUE_TAG" != @* ]]; then
    ISSUE_TAG="@$ISSUE_TAG"
  fi
  if [[ ${#BEHAVE_ARGS[@]} -gt 0 ]]; then
    BEHAVE_ARGS=(--tags "$ISSUE_TAG" "${BEHAVE_ARGS[@]}")
  else
    BEHAVE_ARGS=(--tags "$ISSUE_TAG")
  fi
fi

python3 "$ROOT_DIR/scripts/generate_behave_steps.py"
python3 -m behave "$FEATURE_DIR" "${BEHAVE_ARGS[@]}"
