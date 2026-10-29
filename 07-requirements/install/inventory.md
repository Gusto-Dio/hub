# Inventory (install in this order)

Versions are the ones in use on 2026-10-29 (VM and VDI). "Admin" = needs an Administrator PowerShell. Keep this file in sync with `verify-environment.ps1`.

| # | Item | Check | Install | Admin | Notes |
|---|---|---|---|---|---|
| 1 | Git 2.54.x | `git --version` | `winget install --id Git.Git` | no | Git for Windows ships Git Bash, used by some commands. If TLS fails with schannel: `git -c http.sslBackend=openssl` |
| 2 | Git identity | `git config --global user.name` / `user.email` | `git config --global user.name "Diogenes Ribeiro"`; `git config --global user.email diogenes.ribeiro@gusto.com` | no | Without it commits get the wrong author (`feedback_git_identity_not_configured`) |
| 3 | Node.js 24.x | `node --version` | `winget install --id OpenJS.NodeJS` | no | Needed by Claude Code and `uip` |
| 4 | .NET SDK 8.0.x | `dotnet --list-sdks` | `winget install --id Microsoft.DotNet.SDK.8` | yes | Some Helm/pack steps want .NET 10: then pack with `uipcli.exe` (`reference_pack_with_uipcli_when_helm_needs_dotnet10`) |
| 5 | Python 3.14.x | `python --version` | `winget install --id Python.Python.3.14 --source winget` | yes | Installs per user under `%LOCALAPPDATA%\Programs\Python\Python314`. Error 1625 = not Administrator |
| 6 | Python packages | `python -m pip list` | `python -m pip install pillow boto3` (versions in `../pip-freeze.txt`) | no | Pillow is used by screenshot activities; also check the robot machine (`feedback_staging_robot_missing_pillow`) |
| 7 | User PATH | `[Environment]::GetEnvironmentVariable("Path","User")` | add Python, `Python314\Scripts`, `%APPDATA%\npm` | no | New terminal afterwards |
| 8 | Claude Code 2.1.x | `claude --version` | `npm i -g @anthropic-ai/claude-code --allow-scripts=@anthropic-ai/claude-code` | no | First run: SSO login by Dio |
| 9 | UiPath CLI `uip` 1.204.x | `uip --version` | `npm i -g @uipath/cli`, then the tools: orchestrator, rpa, rpa-legacy, admin, docsai (`uip tools install <name>`) | no | Pack and run need the tools, not just the CLI |
| 10 | UiPath skills | `uip skills install` output; plugin list in Claude | `uip skills install` (30 skills, marketplace at `~/.uipath/.skills`) | no | A skill installed mid-session is only seen by a new session |
| 11 | Chrome | open it | company software | no | Allow carrier pop-ups (BT-76973); extension: see `manual-steps.md` |
| 12 | UiPath Studio | `Test-Path "$env:ProgramFiles\UiPath\Studio\UiPath.Studio.exe"` | company software / IT | maybe | The `rpa-tool` is not supported by Studio on this machine type (`feedback_studio_rpa_tool_unsupported`) |
| 13 | UiPath Chrome extension | `chrome://extensions` | install as **Current User**, never All Users (`feedback_uipath_chrome_extension`) | no | Cannot be checked by script |
| 14 | Excel | file exists | company software | maybe | Needed by Excel activities |
| 15 | PowerShell 5.1 | built in | none | no | `pwsh` 7 is optional; check whether any process still needs `C:\Program Files\PowerShell\7\pwsh.exe` before skipping it |
| 16 | Repo clone | `git -C C:\Projects\biztech-uipath-rpa branch --show-current` | `git clone https://github.com/Gusto/biztech-uipath-rpa C:\Projects\biztech-uipath-rpa` | no | GitHub SSO opens in the browser; confirm default branch `develop` |
| 17 | Hub clone | `git -C C:\Projects\hub log -1` | `git clone https://github.com/Gusto-Dio/hub C:\Projects\hub` | no | Private. Pull regularly |
| 18 | BizTech share | `Test-Path U:\` | `net use U: \\fs3-prd-aws.gustocorp.com\BizTech /persistent:yes` | no | Error 5 = ask IT for access; error 53 = network. Letter is `U:` on the VM (`../network-drives.md`) |
| 19 | `uip login` | `uip login status` | `uip login` (org `gustoinc`) | no | Browser/SSO by Dio. Default tenant Staging. Blocked on the new VM until the AITops login ticket is resolved |
| 20 | Local NuGet folder (optional) | `Test-Path C:\Users\<user>\local-nupk` | created when packing libs locally | no | Only needed for local lib packing; version collisions: `feedback_local_nuget_cache_version_collision` |

## Not installed on purpose
- `gh` CLI: use the `githubgusto` MCP.
- `jq`: validate JSON with Python.
- Do not install tools to get around a check or a permission block; ask Dio.

## After a lasting change on the working machine
Update the row here, `../README.md` (versions) and `verify-environment.ps1`, then commit the hub.
