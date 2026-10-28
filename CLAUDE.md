# Dio's Hub — BizTech / BenOps RPA (Gusto)

This file goes to `~/.claude/CLAUDE.md` on a new machine. It tells Claude who I am, how I work and where the accumulated knowledge lives.

## Who I am
- Diogenes Ribeiro (Dio), diogenes.ribeiro@gusto.com, BizTech / BenOps RPA team, Gusto.
- I work on UiPath RPA (Studio, Orchestrator, `uip` CLI) in the repo `Gusto/biztech-uipath-rpa`. Default branch: `develop`.
- I talk to Claude in Portuguese. **Jira comments and PR bodies are always written in English.**
- Machine: AWS VM (replaced the Porto VDI on 2026-10-28). Repo clone: `C:\Projects\biztech-uipath-rpa`. Hub clone: `C:\Projects\hub`. The BizTech network share is mapped as `U:` on the VM. Old memories that mention `U:\Projects\...` or `Z:` are historical.

## Where the knowledge is
Everything is in `hub/` (this repository). Read what is relevant before acting:
- `01-credentials/`: WHERE credentials live and how to get them back. Never values.
- `02-platforms/`: UiPath, Buildkite, GitHub, Jira, Slack, carrier portals.
- `03-tools/`: scripts, Claude commands, shortcuts.
- `04-process-history/`: one file per ticket/process (`project_*.md`).
- `05-session-history/`: `work_state.md` and the memory index `MEMORY.md`.
- `06-learnings/`: rules and pitfalls (`feedback_*.md`, `reference_*.md`, `uip_rpa_cli_reference.md`).
- `07-requirements/`: versions, network drives and the environment setup steps.

Memory files have frontmatter (`name`, `description`, `metadata.type`). Their content is mostly in Portuguese, which is fine. `05-session-history/MEMORY.md` is the index: read it first and open only what you need.

## Standing rules (summary; details in 06-learnings)
- **Security (company policy):** company data never goes to a personal or public destination. No secrets and no real PII in versioned files. Local work is free; any push or share requires confirming the destination first.
- **PRs and commits:** no AI signature or co-author, plain text without tables or markdown, English (`feedback_pr_no_claude_signature_no_tx_table`). No `gh` CLI: use the `githubgusto` MCP. If git fails with a schannel TLS error: `git -c http.sslBackend=openssl`.
- **Jira closing comments:** short, simple, non-technical (`feedback_jira_closing_comment_simple_nontechnical`).
- **`uip`:** run `uip login status` before touching a tenant. The default tenant is Staging, never assume Production. For a Production action: `uip login tenant set Production`, do the action, re-read to verify, then `uip login tenant set Staging`. Tests always via `uip or jobs start`.
- **Production:** reads and writes need explicit approval (the auto mode blocks them). Buildkite auto-deploys only Production, and only publishes to the feed: it never activates the Process. After a deploy, check `uip or processes list` (`ProcessVersion`), because the Process can be several versions behind the feed (`feedback_process_version_can_lag_behind_feed`). A Process rebind needs explicit approval and the real ProcessKey GUID.
- **Pack:** `uip rpa pack` needs `--package-id` and a `git branch --show-current` check first. If Helm needs .NET 10, use `uipcli.exe` with an absolute project path; it rewrites `project.json` and deletes `entry-points.json`, so restore them (`reference_pack_with_uipcli_when_helm_needs_dotnet10`).
- **Buildkite dependency checks (strict since 2026-10-27/28):** every changed project must match `dependencylock.json` exactly, and `projectVersion` must be bumped in every PR. Bots under `Processes/` may only depend on `Gusto_*` libraries and must target Windows or Portable (`feedback_dependencylock_strict_no_skip_since_oct_2026`, `feedback_bots_only_gusto_dependencies_check_since_28oct`). A PR can pass its own CI and still fail the `develop` build if a new check landed in between, so read `.buildkite/check_dependency.sh` from `origin/develop` before opening a PR.
- Before editing a similar "sibling" process, confirm the project GUID (`feedback_verify_process_guid_before_editing_sibling`).
- `jq` is not installed on the VM: validate `project.json` and the lock with Python.

## First session on a new machine
Run `07-requirements/README.md` (install), then `01-credentials/README.md` (logins). To restore the memory: `03-tools/scripts/restore-memory.ps1`.

## Keeping the hub current
After a session that changes memory, copy the memory files back into `04-process-history` (`project_*`), `05-session-history` (`MEMORY.md`, `work_state.md`) and `06-learnings` (everything else), then commit and push. The push needs explicit approval and the destination is the private repo `Gusto-Dio/hub` only.
