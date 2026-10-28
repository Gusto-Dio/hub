# Environment requirements

Versions as of the AWS VM setup (2026-10-28). The `benops-rpa-setup` command (in `03-tools/claude-commands`) runs the health check; use it together with this file.

| Item | Version |
|---|---|
| Windows | Server 2025 Datacenter 10.0.26100 |
| .NET SDK | 8.0.x (Helm may require .NET 10, then use uipcli) |
| Python | 3.14.x (`winget install --id Python.Python.3.14 --source winget`, needs Administrator; see `pip-freeze.txt`: Pillow, boto3) |
| Node.js | 24.x |
| Git | 2.54.x (identity: `Diogenes Ribeiro` / diogenes.ribeiro@gusto.com) |
| UiPath CLI `uip` | 1.204.x (`npm i -g @uipath/cli`, then the tools orchestrator, rpa, rpa-legacy, admin, docsai) |
| Claude plugin | `uipath@uipath-marketplace` (install the skills with `uip skills install`) |
| Excel | needed for Excel activities |
| UiPath Studio + Chrome extension | extension installed as **Current User** (not All Users) |
| PowerShell | 5.1 (pwsh optional) |

User PATH must include Python, its `Scripts` folder and `%APPDATA%\npm`. Read it with `[Environment]::GetEnvironmentVariable("Path","User")`, never `$env:Path`.

## Steps
1. Install the tools above (winget/npm/pip; see benops-rpa-setup).
2. `git config --global user.name "Diogenes Ribeiro"` and `git config --global user.email diogenes.ribeiro@gusto.com`.
3. Clone `Gusto/biztech-uipath-rpa` to `C:\Projects\biztech-uipath-rpa`; confirm `develop`.
4. Map the network drive (`network-drives.md`).
5. `uip login` then `uip login status` (org `gustoinc`; default tenant Staging).
6. Copy `CLAUDE.md` to `~/.claude/CLAUDE.md`; run `restore-memory.ps1 -ProjectPath C:\Projects\biztech-uipath-rpa`.
7. Install plugins/MCPs (benops-rpa-setup) and authenticate the connectors again in `/mcp`.
8. Chrome: allow the carriers' pop-ups (see BT-76973) and install the UiPath extension as Current User.
9. `jq` is not available on the VM; validate JSON with Python. For packing see `reference_pack_with_uipcli_when_helm_needs_dotnet10`.

## Claude settings
The current `settings.json` enables `uipath@uipath-marketplace` (local marketplace `~/.uipath/.skills`), `tui: fullscreen`, theme `dark-ansi` and an `autoMode` block specific to this repo. Recreate it with `/config` and `/install-permissions` instead of copying.
