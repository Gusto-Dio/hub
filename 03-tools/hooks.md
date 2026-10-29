# Hooks

A hook is run by the Claude Code harness, not by the model, so it is the only way to GUARANTEE a rule. `CLAUDE.md` and memory are instructions the model usually follows. Use hooks for the rules that must never fail.

## uipath-edit-guard (installed 2026-10-29 on the old VDI; install on the VM too)
Status: installed in the VDI `~/.claude/settings.json` (backup: `settings.json.bak-pre-hook`) with the hub path `U:\hub`. On the VM it is NOT installed yet: add the snippet below with `C:\Projects\hub`. It loads at session start, so it applies from the next session.
Script: `03-tools/scripts/hooks/uipath-edit-guard.ps1`. Tested with simulated input: blocks (exit 2) an edit of `.xaml`, `.cs` or `project.json` when
1. the repo is on `develop` or `main`, or
2. the skill `uipath:uipath-rpa` was not invoked in this session (a `Mark` hook records the invocation in `%TEMP%\uipath-rpa-skill-<session_id>.ok`).

Add to `~/.claude/settings.json` (merge with the existing keys; adjust the hub path: `C:\Projects\hub` on the VM, `U:\hub` on the VDI):
```json
"hooks": {
  "PostToolUse": [
    { "matcher": "Skill",
      "hooks": [ { "type": "command",
        "command": "powershell -NoProfile -File C:\\Projects\\hub\\03-tools\\scripts\\hooks\\uipath-edit-guard.ps1 -Mode Mark" } ] }
  ],
  "PreToolUse": [
    { "matcher": "Edit|Write|MultiEdit",
      "hooks": [ { "type": "command",
        "command": "powershell -NoProfile -File C:\\Projects\\hub\\03-tools\\scripts\\hooks\\uipath-edit-guard.ps1 -Mode Guard" } ] }
  ]
}
```
Notes:
- A skill invoked through a slash command by Dio may not pass through the Skill tool; if the guard blocks in that case, invoke the skill once via the Skill tool.
- Subagents have their own session id, so they are blocked until they invoke the skill too. That is intended.
- The marker files live in `%TEMP%` and are harmless. Delete them if a session id is ever reused.
- If the guard blocks wrongly, say so to Dio; do not work around it by editing through Bash.

## Other candidates (not built)
- Block `git push` to `develop` and `--no-verify` (PreToolUse on Bash).
- Block writing `.env` or credential-looking strings into tracked files (PreToolUse on Write/Edit).
- Remind at session start to read `00-rules/README.md` (SessionStart hook).
