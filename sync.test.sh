#!/usr/bin/env bash
set -euo pipefail

REPO_DIR=$(cd "$(dirname "$0")" && pwd)
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

assert_eq() {
  local expected=$1 actual=$2 msg=$3
  if [ "$expected" != "$actual" ]; then
    printf 'FAIL: %s\n  expected: %s\n  actual:   %s\n' "$msg" "$expected" "$actual" >&2
    exit 1
  fi
}

# 1. Fresh install creates Codex symlinks and Cursor local plugin rule.
HOME_1="$TMP/home1"
mkdir -p "$HOME_1/.claude/skills/demo"
printf 'Hello from CLAUDE.md\n' > "$HOME_1/.claude/CLAUDE.md"
HOME="$HOME_1" "$REPO_DIR/sync.sh"

assert_eq "$HOME_1/.claude/skills" "$(readlink "$HOME_1/.agents/skills")" "codex skills symlink"
assert_eq "$HOME_1/.claude/CLAUDE.md" "$(readlink "$HOME_1/.codex/AGENTS.md")" "codex AGENTS.md symlink"
assert_eq "true" "$([ -f "$HOME_1/.cursor/plugins/local/claude-md/.cursor-plugin/plugin.json" ] && echo true || echo false)" "cursor plugin manifest"

RULE="$HOME_1/.cursor/plugins/local/claude-md/rules/claude-md.mdc"
grep -q '^alwaysApply: true$' "$RULE"
grep -q '^Hello from CLAUDE.md$' "$RULE"

# 2. Idempotent: second run does not rewrite unchanged rule file.
BEFORE_INODE=$(ls -i "$RULE" | awk '{print $1}')
HOME="$HOME_1" "$REPO_DIR/sync.sh"
AFTER_INODE=$(ls -i "$RULE" | awk '{print $1}')
assert_eq "$BEFORE_INODE" "$AFTER_INODE" "unchanged rule keeps inode"

# 3. Edits propagate into Cursor rule.
printf 'Updated instruction\n' > "$HOME_1/.claude/CLAUDE.md"
HOME="$HOME_1" "$REPO_DIR/sync.sh"
grep -q '^Updated instruction$' "$RULE"

# 4. Empty or removed CLAUDE.md removes the Cursor rule.
rm -f "$HOME_1/.claude/CLAUDE.md"
HOME="$HOME_1" "$REPO_DIR/sync.sh"
assert_eq "false" "$([ -e "$RULE" ] && echo true || echo false)" "removed CLAUDE.md deletes rule"

# 5. Refuses to clobber an existing non-symlink ~/.codex/AGENTS.md.
HOME_2="$TMP/home2"
mkdir -p "$HOME_2/.claude" "$HOME_2/.codex"
printf 'source\n' > "$HOME_2/.claude/CLAUDE.md"
printf 'handwritten\n' > "$HOME_2/.codex/AGENTS.md"
if HOME="$HOME_2" "$REPO_DIR/sync.sh" 2>/dev/null; then
  printf 'FAIL: should refuse to overwrite non-symlink AGENTS.md\n' >&2
  exit 1
fi
assert_eq "handwritten" "$(cat "$HOME_2/.codex/AGENTS.md")" "non-symlink AGENTS.md preserved"

printf 'PASS\n'
