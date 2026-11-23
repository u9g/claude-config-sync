#!/usr/bin/env bash
set -euo pipefail

CLAUDE_DIR="$HOME/.claude"
CLAUDE_MD="$CLAUDE_DIR/CLAUDE.md"
CLAUDE_SKILLS="$CLAUDE_DIR/skills"

ensure_symlink() {
  local target=$1
  local link=$2
  mkdir -p "$(dirname "$link")"
  if [ -L "$link" ]; then
    [ "$(readlink "$link")" = "$target" ] && return 0
    ln -sfn "$target" "$link"
  elif [ -e "$link" ]; then
    printf 'refusing to overwrite non-symlink: %s\n' "$link" >&2
    return 1
  else
    ln -s "$target" "$link"
  fi
}

# Codex reads ~/.agents/skills and ~/.codex/AGENTS.md natively.
if [ -d "$CLAUDE_SKILLS" ]; then
  ensure_symlink "$CLAUDE_SKILLS" "$HOME/.agents/skills"
fi
if [ -e "$CLAUDE_MD" ]; then
  ensure_symlink "$CLAUDE_MD" "$HOME/.codex/AGENTS.md"
fi

# Cursor reads ~/.claude/skills natively, and loads alwaysApply .mdc rules from
# ~/.cursor/plugins/local/<plugin>/rules/ in every workspace regardless of cwd.
# Its plugin fetcher rejects symlinks escaping the plugin directory, so mirror as a file.
PLUGIN_DIR="$HOME/.cursor/plugins/local/claude-md"
MANIFEST_DIR="$PLUGIN_DIR/.cursor-plugin"
MANIFEST="$MANIFEST_DIR/plugin.json"
RULE_DIR="$PLUGIN_DIR/rules"
RULE="$RULE_DIR/claude-md.mdc"

mkdir -p "$MANIFEST_DIR" "$RULE_DIR"

write_if_changed() {
  local dest=$1
  local tmp
  tmp=$(mktemp "$(dirname "$dest")/.$(basename "$dest").XXXXXX")
  trap 'rm -f "$tmp"' RETURN
  cat > "$tmp"
  if [ ! -f "$dest" ] || ! cmp -s "$tmp" "$dest"; then
    chmod 0644 "$tmp"
    mv "$tmp" "$dest"
  fi
}

write_if_changed "$MANIFEST" <<'JSON'
{
  "name": "claude-md",
  "displayName": "CLAUDE.md",
  "version": "1.0.0",
  "description": "User instructions mirrored from ~/.claude/CLAUDE.md."
}
JSON

if [ ! -s "$CLAUDE_MD" ]; then
  rm -f "$RULE"
  exit 0
fi

{
  printf '%s\n' '---'
  printf '%s\n' 'description: User instructions mirrored from ~/.claude/CLAUDE.md'
  printf '%s\n' 'alwaysApply: true'
  printf '%s\n\n' '---'
  cat "$CLAUDE_MD"
} | write_if_changed "$RULE"
