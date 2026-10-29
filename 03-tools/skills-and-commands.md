# Skills and commands

Commands live in `~/.claude/commands/` (copy of `03-tools/claude-commands/`). UiPath skills come from the `uipath@uipath-marketplace` plugin (`uip skills install`). The BenOps commands also exist in the plugin `benops-rpa@benops-rpa-skills` (`claude plugins install benops-rpa@benops-rpa-skills`).

## Which one for which task
| Task | Use |
|---|---|
| Any `.xaml`/`.cs`/`project.json` edit, build, validate, pack, run | skill `uipath:uipath-rpa` (mandatory first, see `../00-rules/xaml-and-skills.md`) |
| A process is failing in Production, new bug ticket | `/benops-triage-agent` first response, then `/benops-ticket-investigation BT-XXXXX` (logs before code); `uipath:uipath-troubleshoot` for causal analysis |
| Orchestrator: queues, assets, jobs, triggers, processes, libraries, folders | `uipath:uipath-platform` |
| Review the branch before a PR | `/analyze` |
| Review without editing | `uipath:uipath-review` |
| Legacy to Windows migration, classic activities to modern | `uipath:uipath-activity-migrator` |
| Create Staging test cases from a Jira ticket | `/uipath-test-cases-from-ticket` |
| Daily briefing (Slack, Jira, GitHub, priority contacts) | `/morning` |
| Status update to Sri / Oscar | `/followup` (format in `feedback_sri_status_update_format`) |
| Sync the Notion hub with PR and Jira status | `/benops-sync` |
| New teammate or new machine setup | `/benops-rpa-setup`, then `../07-requirements/README.md` |
| Tenant/org/identity admin and audit | `uipath:uipath-admin` |

## Notes
- Slash commands and skills are only recognized after the session starts: a skill installed or updated mid-session needs a new session (`feedback_skill_registry_midsession_lag`).
- `/uipath-migration-repair` appears in the team template but is not installed here; use `uipath:uipath-activity-migrator` or `uipath:uipath-troubleshoot`.
- Project context for UiPath work can be regenerated with the `uipath-project-discovery-agent` (writes `.claude/rules/project-context.md` and `AGENTS.md` in the repo; do not commit them without asking).
- Hooks that enforce the XAML protocol: `hooks.md`.
