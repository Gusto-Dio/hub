# hub

Portable knowledge base for Dio to work with Claude Code. Built to switch VDI/VM without starting from scratch.

| Folder | Content |
|---|---|
| 01-credentials | where credentials live and how to recover them (no values) |
| 02-platforms | UiPath, Buildkite, GitHub, Jira, Slack, carriers |
| 03-tools | Claude commands, scripts, repo tools |
| 04-process-history | history per ticket/process |
| 05-session-history | work_state and the memory index |
| 06-learnings | rules, pitfalls, references |
| 07-requirements | versions, network drives and environment setup |

## How to use it on a new machine
1. `git clone` this repo (private: `Gusto-Dio/hub`; SSO login opens in the browser).
2. Install Claude Code and open `claude` inside the cloned folder.
3. Say: "Read CLAUDE.md and 07-requirements/README.md, install what is missing and then restore the memory."
4. Copy `CLAUDE.md` to `~/.claude/CLAUDE.md`.
5. After later changes: `git -C C:\Projects\hub pull`, then run `03-tools/scripts/restore-memory.ps1` again.

## Golden rule
No secrets here. Passwords, tokens, `.credentials.json`, `~/.uipath/.auth` and `.env` never enter this repo. See `01-credentials`.
