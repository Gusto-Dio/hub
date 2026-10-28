# Credentials: where they are (NEVER the values)

Policy: no secret in this repo. This is only the map of where each thing lives and how to redo the access on a new machine.

| Access | Where it really lives | How to redo it on a new machine |
|---|---|---|
| UiPath CLI (`uip`) | interactive login saved in `~/.uipath/.auth` (do not copy) | `uip login` (org `gustoinc`), then `uip login tenant list`. Default tenant is Staging (see `02-platforms/uipath.md`) |
| Orchestrator Credential assets (Credential_BSCA, etc.) | Orchestrator, per folder; read through `GetRobotCredential` | nothing to copy; the robot reads them directly |
| Claude Code | `~/.claude/.credentials.json` (do not copy) | `claude` then SSO login |
| GitHub | token/SSO of the Gusto account | git credential manager, Gusto org SSO (no `gh` CLI; use the `githubgusto` MCP) |
| Jira/Confluence, Slack, Buildkite, Gmail, Sheets | Claude connectors (MCP, claude.ai) | authenticate again in `/mcp` |
| Carrier MFA/SMS vault | Google Voice then Gmail (see `project_bt76628*`) | access through the Gusto account |
| Google service account key (QueueBuilder) | asset in Orchestrator | nothing to copy |
| Network shares (BizTech: robot credentials, Locks) | `\fs3-prd-aws.gustocorp.com\BizTech`, mapped as `U:` on the AWS VM | see `07-requirements/network-drives.md` |

## Do not copy into the repo
`~/.claude/.credentials.json`, `~/.uipath/.auth`, `~/.uipath/*`, `.env`, `.env.local`, any `*.pfx` or `*.key`.

## Tip
If something fails with "invalid credentials", before suspecting the code check the login circuit breaker in `06-learnings/reference_login_circuit_breaker_locks_share.md`.
