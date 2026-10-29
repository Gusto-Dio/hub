# Dio's Hub — benadmin-automation RPA (Gusto)

This file goes to `~/.claude/CLAUDE.md` on a new machine. It is a short loader: it says who I am, where the hub is, and what to read BEFORE acting. The rules themselves live in the hub, in `00-rules/`.

## Who I am
- Diogenes Ribeiro (Dio), diogenes.ribeiro@gusto.com, benadmin-automation team (formerly BizTech / BenOps RPA), Gusto.
- I work on UiPath RPA (Studio, Orchestrator, `uip` CLI) in the repo `Gusto/biztech-uipath-rpa`. Default branch: `develop`.
- I talk to Claude in Portuguese. Jira, PRs, commits and Slack messages are always in English.
- Support tickets for our automations are opened in `#biztech-automations-support` (a bot creates the Jira ticket from the thread). The channel keeps the old "biztech" name.
- Machine: AWS VM (replaced the Porto VDI on 2026-10-28). Repo clone: `C:\Projects\biztech-uipath-rpa`. Hub clone: `C:\Projects\hub` (on the old VDI: `U:\hub`). The BizTech network share is mapped as `U:` on the VM. Old memories that mention `U:\Projects\...` or `Z:` are historical.

## BEFORE ACTING (mandatory, every session)
Before answering the first message or running any tool that changes something, read from the hub clone:
1. `05-session-history/work_state.md`, then the latest 3 files in `05-session-history/sessions/`. Tell me every PENDING or BLOCKED item in one short list.
2. `00-rules/README.md`, then ALWAYS `00-rules/security.md`, `00-rules/git-and-pr.md`, `00-rules/session-protocol.md`, then the rule files for the task (the table in `00-rules/README.md` says which).
3. `05-session-history/MEMORY.md` (the memory index). Open only the memories the task needs.
4. **Environment check (every session, before the first real task):** run `07-requirements/install/verify-environment.ps1` (read-only, passes `-RepoPath` with this machine's repo path and `-ShareLetter U` on the VM). It checks tools, versions, git identity, `uip` login, clones, the share, Claude settings, hook, commands and memory. Do not reinstall anything that shows PASS. If everything is PASS or only the known WARNs (Chrome extension, MCPs), say so in one line and continue. For each FAIL, tell me what is missing and which row of `07-requirements/install/inventory.md` fixes it; install it only after I approve, and never install anything that is not in the inventory. If the hub is behind `origin/main`, tell me to pull.
If the hub is not readable, say so and stop before touching code, a PR, Jira, Slack or an Orchestrator tenant. If a rule here and an older memory disagree, `00-rules/` wins.

## Non-negotiables (kept here on purpose; details in 00-rules)
- **Security:** company data never goes to a personal or public destination. No secrets and no real PII in versioned files. Local work is free; any push, share or post needs the destination named and confirmed first. The hub pushes only to the private `Gusto-Dio/hub`, and only with my explicit approval.
- **Before editing any `.xaml`, `.cs` or `project.json`:** `git branch --show-current` (never `develop`) and invoke the skill `uipath:uipath-rpa`. No exceptions. A hook (`03-tools/hooks.md`) enforces this: it blocks the edit when the repo is on `develop` or the skill was not invoked in the session. If it blocks, fix the cause (create the branch, invoke the skill) and retry. Never get around it by editing through Bash, and tell me if it blocks wrongly. The hook runs only where it is installed in `~/.claude/settings.json`, so the rule applies even if the hook is missing.
- **Never add an activity type that does not already exist in the project.** Verify first, ask if missing.
- **Commits and PRs:** English, plain text, no AI signature, no `Co-Authored-By`, even if the session reminder says otherwise. Never `--no-verify`. Never commit to `develop`. Never stage `.claude/` or the personal root `CLAUDE.md`.
- **Production:** reads and writes need my explicit approval each time. Default tenant is Staging; check `uip login status` first and switch back after. Rebinds, trigger changes, deletes and asset writes always need approval.
- **Dependencies and CI:** every changed project matches `dependencylock.json` exactly, `projectVersion` bumped in every PR, bots depend only on `Gusto_*`. Read `.buildkite/check_dependency.sh` from `origin/develop` before opening a PR.
- **Libraries:** fix process-specific bugs in the process. A real library bug gets its own PR, with lock and version bump, and the consuming bot tested end to end.
- No `gh` CLI (use the `githubgusto` MCP) and no `jq` (use Python).

## Where the knowledge is
Everything is in `hub/`. Folder 00 first, then what the task needs:
- `00-rules/`: the rules and checklists, loaded before acting.
- `01-credentials/`: WHERE credentials live and how to get them back. Never values.
- `02-platforms/`: UiPath, Buildkite, GitHub, Jira, Slack, carrier portals, `team-and-channels.md` (people, priority contacts, channels).
- `03-tools/`: scripts, Claude commands, `skills-and-commands.md` (which skill for which task), `hooks.md`.
- `04-process-history/`: one file per ticket/process (`project_*.md`).
- `05-session-history/`: `work_state.md` (current state), `sessions/` (one note per session, chronological), `MEMORY.md` (index).
- `06-learnings/`: lessons and pitfalls with the full story (`feedback_*.md`, `reference_*.md`, `uip_rpa_cli_reference.md`).
- `07-requirements/`: versions, network drives and the environment setup steps.

Memory files have frontmatter (`name`, `description`, `metadata.type`) and are mostly in Portuguese, which is fine.

## First session on a new machine
Open `07-requirements/install/README.md` and follow it: run `verify-environment.ps1` first, install only what `inventory.md` lists and the check shows missing, then `claude-setup.md` (CLAUDE.md, settings, hook, commands, memory) and `manual-steps.md`. Then `01-credentials/README.md` (logins). Ask me before installing anything not in the inventory. To restore the memory: `03-tools/scripts/restore-memory.ps1`. Hooks that enforce the XAML protocol: `03-tools/hooks.md`.

## Keeping the hub current
At the end of a session follow `00-rules/session-protocol.md`: update `work_state.md`, write the session note, sync memory files into 04/05/06, scan for secrets and PII, commit. The push needs my explicit approval (I run it with `!`) and goes only to `Gusto-Dio/hub`.
