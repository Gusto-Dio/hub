# Claude Code configuration

Do this after inventory items 1 to 10 and 16 to 17 (Claude installed, repo and hub cloned). `<hub>` = `C:\Projects\hub` on the VM.

1. **Global instructions:** `Copy-Item <hub>\CLAUDE.md $env:USERPROFILE\.claude\CLAUDE.md -Force`. Repeat after every hub pull that changes `CLAUDE.md`; the verify script warns when they differ.
2. **Memory:** `powershell -NoProfile -File <hub>\03-tools\scripts\restore-memory.ps1 -ProjectPath C:\Projects\biztech-uipath-rpa`. Expect 138 or more files. Re-run after pulls that change memory.
3. **Commands:** copy `<hub>\03-tools\claude-commands\*` into `$env:USERPROFILE\.claude\commands\` (analyze, morning, followup, benops-sync, benops-triage-agent, benops-ticket-investigation, uipath-test-cases-from-ticket, benops-rpa-setup).
4. **settings.json** (`$env:USERPROFILE\.claude\settings.json`): do NOT copy the old one. Merge only these keys and keep existing ones:
   - `enabledPlugins`: `{"uipath@uipath-marketplace": true}`
   - `extraKnownMarketplaces`: `uipath-marketplace` with `source` = directory `C:\Users\<user>\.uipath\.skills` and `autoUpdate: true` (the folder is created by `uip skills install`)
   - `tui`: `fullscreen`, `theme`: `dark-ansi` (preferences, optional)
   - `hooks`: the XAML guard (step 5)
   - `autoMode`: recreate with `/config` and `/install-permissions`. The old block pointed at `U:\Projects\biztech-uipath-rpa` as the trusted repo; on the VM the repo is `C:\Projects\biztech-uipath-rpa`, so update the trusted repo line to the new path.
   Edit JSON with a script (Python or `ConvertFrom-Json`), keep a backup copy first, and verify the other keys are unchanged afterwards.
5. **Hook (XAML protocol).** Merge into `settings.json` under `hooks` (script path = this machine's hub):
   ```json
   "hooks": {
     "PostToolUse": [ { "matcher": "Skill", "hooks": [ { "type": "command",
       "command": "powershell -NoProfile -File C:\\Projects\\hub\\03-tools\\scripts\\hooks\\uipath-edit-guard.ps1 -Mode Mark" } ] } ],
     "PreToolUse":  [ { "matcher": "Edit|Write|MultiEdit", "hooks": [ { "type": "command",
       "command": "powershell -NoProfile -File C:\\Projects\\hub\\03-tools\\scripts\\hooks\\uipath-edit-guard.ps1 -Mode Guard" } ] } ]
   }
   ```
   It only takes effect in a NEW session. Details and behavior: `../../03-tools/hooks.md`.
6. **Plugin for BenOps commands (optional):** `claude plugins install benops-rpa@benops-rpa-skills` (the commands in step 3 are the same files).
7. **MCP connectors:** open `/mcp` in Claude and authenticate again: GitHub (`githubgusto`), Jira/Confluence (`jiraconfluencegusto`), Slack, Notion, Buildkite, Gmail, Sheets/Docs. Dio does the browser logins.
8. **Final test:** start `claude` inside `C:\Projects\biztech-uipath-rpa` and ask something only the memory knows (for example, the state of BT-77083 or which Process version is bound). Then edit-test the hook in a scratch branch: an edit of a `.xaml` before invoking `uipath:uipath-rpa` must be blocked.

Do not copy: `~/.claude/.credentials.json`, `~/.uipath/.auth`, `history.jsonl`, session transcripts, `settings.local.json` (permissions are rebuilt through use and `/install-permissions`).
