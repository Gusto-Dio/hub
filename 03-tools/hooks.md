# Hooks

A hook is run by the Claude Code harness, not by the model, so it is the only way to GUARANTEE a rule. `CLAUDE.md` and memory are instructions the model usually follows. Use hooks for the rules that must never fail.

## uipath-edit-guard (installed 2026-10-29 on the old VDI and on the VM)
VM status (2026-10-29): installed in `~/.claude/settings.json` (backup: `settings.json.bak-pre-hook`), pointing straight to `C:\Projects\hub\03-tools\scripts\hooks\uipath-edit-guard.ps1` (the hub is on a local drive, so no local copy is needed). Tested with simulated input: a `.xaml` edit on `develop` is blocked (exit 2), a `.txt` edit passes (exit 0). Not yet seen in a real session; it loads at session start, so the first `.xaml` edit of the next session is the first real test. The VM `settings.json` has no `autoMode` block, so nothing to repoint there.
VDI status: installed in the VDI `~/.claude/settings.json` (backup: `settings.json.bak-pre-hook`). On the VDI the commands point to a LOCAL copy, `C:\Users\<user>\.claude\hooks\uipath-edit-guard.ps1`, because the hub lives on `U:` (a network drive) and the machine policy `RemoteSigned` refuses unsigned scripts from there. Never fix that with `-ExecutionPolicy Bypass`: the auto mode blocks it as weakening security, and it is not needed. Keep the local copy in sync with the hub script after any change. The snippet below is what the VM uses (path `C:\Projects\hub`).
Script: `03-tools/scripts/hooks/uipath-edit-guard.ps1`. Tested with simulated input: blocks (exit 2) an edit of `.xaml`, `.cs` or `project.json` when
1. the repo is on `develop` or `main`, or
2. the skill `uipath:uipath-rpa` was not invoked in this session (a `Mark` hook records the invocation in `%TEMP%\uipath-rpa-skill-<session_id>.ok`).

Add to `~/.claude/settings.json` (merge with the existing keys). The script path must be on a LOCAL drive: `C:\Projects\hub\...` on the VM works; if the hub is on a network drive, copy the script to `~/.claude/hooks/` and point to that copy:
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
