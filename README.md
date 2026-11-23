# claude-config-sync

Mirrors `~/.claude/CLAUDE.md` and `~/.claude/skills` into Codex and Cursor in each tool's native format so Claude Code stays the single source of truth.

## What it wires up

| Target | Skills | `CLAUDE.md` |
|---|---|---|
| **Codex** | `~/.agents/skills` → `~/.claude/skills` (symlink) | `~/.codex/AGENTS.md` → `~/.claude/CLAUDE.md` (symlink) |
| **Cursor** | Native (`~/.claude/skills` & `~/.codex/skills`) | Local plugin `~/.cursor/plugins/local/claude-md/rules/claude-md.mdc` (`alwaysApply: true`), synced via `launchd` `WatchPaths` |

Why Cursor uses a synced local plugin instead of a symlink or `~/.cursor/rules`:
- Cursor `.mdc` rules require `alwaysApply: true` YAML frontmatter to apply globally.
- Cursor's plugin loader rejects symlinks whose target escapes the plugin directory.
- `~/.cursor/rules` only applies under `$HOME` when project settings are enabled, whereas a user-local plugin under `~/.cursor/plugins/local/` loads in every workspace (including `/tmp` and sandboxed sessions).

## Install (macOS)

```sh
make install
```

This runs `./sync.sh` once and installs `~/Library/LaunchAgents/com.u9g.claude-config-sync.plist`, which uses `launchd` `WatchPaths` on `~/.claude/CLAUDE.md` (no background daemon, no polling) to rewrite `claude-md.mdc` whenever `CLAUDE.md` changes.

## Test / Uninstall

```sh
make test
make uninstall
```
