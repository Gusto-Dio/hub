# Manual steps (only a human can do these)

Status as of 2026-10-29 for the AWS VM. Update when something changes.

| Step | Who | Status |
|---|---|---|
| Google/Okta login of diogenes.ribeiro@gusto.com on the VM (blocked by "Google couldn't verify this account", new AWS IP/device) | AITops / IT, ticket opened 2026-10-28; Oscar informed | BLOCKED. Without it: no `uip login`, no Orchestrator, no MCP connectors |
| `uip login` (org `gustoinc`), then `uip login status` shows Staging | Dio (browser) | waits for the item above |
| Claude Code SSO login | Dio | done |
| GitHub SSO for the clones | Dio | done |
| MCP connectors authentication in `/mcp` | Dio | waits for the login item |
| Request IT access to `\\fs3-prd-aws.gustocorp.com\BizTech` (robot credentials, Locks). Dio mapped it as `U:`; the request to IT still needs to be filed | Dio / IT | content of `U:` on the VM not yet verified |
| Chrome: allow pop-ups for the carrier sites; install the UiPath extension as Current User | Dio | not confirmed |
| Administrator PowerShell for winget installs that need it (.NET SDK, Python) | Dio | done for the current tools |
| Push of hub changes (auto mode blocks it): `! git -C /u/hub -c http.sslBackend=openssl push origin main` on the VDI; on the VM use the Windows path | Dio | per change |
| Install the hook on the VM (`claude-setup.md` step 5) | Claude prepares, Dio approves the settings change | not done |

When a step is finished, change its status here and re-run `verify-environment.ps1`.
