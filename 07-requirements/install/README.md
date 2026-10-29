# Installation guide for a new machine (read by Claude on the new VM)

Goal: bring a fresh Windows machine to the same state as the working one, without guessing and without installing things that are not listed.

## How Claude should run this
1. Run the check first, change nothing yet:
   `powershell -NoProfile -File <hub>\07-requirements\install\verify-environment.ps1 -RepoPath C:\Projects\biztech-uipath-rpa -ShareLetter U`
   It prints PASS / WARN / FAIL for every item in `inventory.md`.
2. For each FAIL, open the matching row in `inventory.md` and tell Dio in one short list: what is missing, what you will run, whether it needs Administrator or Dio's hands (login, MFA, IT).
3. Install in the order of `inventory.md` (the order matters: Git and Node before the CLIs, `uip` before its login, the repo before the memory). One item at a time, then re-run the check for that item.
4. Do the Claude configuration in `claude-setup.md` (CLAUDE.md, settings, hooks, commands, memory).
5. Finish with the manual items that no script can check (`manual-steps.md`).
6. Run the verify script again; report the final PASS/WARN/FAIL counts honestly, and what is still blocked and by whom.

## Rules for the installer
- Install only what `inventory.md` lists, at the listed version line. If something else seems needed, ask Dio and add it to the inventory afterwards.
- Administrator rights: only Dio can grant them. Do not try to bypass UAC or change security settings. Python needs Administrator (`winget` error 1625 without it).
- Anything that needs a login, MFA or SSO (Claude, `uip login`, GitHub, MCP connectors) is done by Dio in the browser; Claude prepares the command and waits.
- Never copy credentials, tokens, `.credentials.json`, `~/.uipath/.auth` or `.env` between machines (`../../00-rules/security.md`).
- Read the user PATH with `[Environment]::GetEnvironmentVariable("Path","User")`, never `$env:Path`; open a NEW terminal after changing PATH.
- Do not push the hub from the new machine without Dio's explicit approval.
- When something changes on the working machine (new tool, new version, new hook), update `inventory.md` and the verify script in the same commit.

## Files
- `inventory.md`: everything to install, in order, with the check, the command and the notes.
- `claude-setup.md`: Claude Code configuration (CLAUDE.md, settings.json, hook, commands, plugin, memory, MCPs).
- `manual-steps.md`: what only a human can do (logins, IT requests, browser settings).
- `verify-environment.ps1`: read-only check of all of the above.
- `../README.md`, `../network-drives.md`, `../pip-freeze.txt`: versions, drive mapping, Python packages.
