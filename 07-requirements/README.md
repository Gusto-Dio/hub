# Requirements do ambiente

Versões da VDI atual (27/10/2026). O comando `benops-rpa-setup` (em `03-ferramentas/claude-commands`) faz o health check; use-o junto.

| Item | Versão |
|---|---|
| Windows | Server 2025 Datacenter 10.0.26100 |
| .NET SDK | 8.0.422 (Helm pode exigir .NET 10 → usar uipcli) |
| Python | 3.14.6 em `C:\Python314\python.exe` (+ `pip-freeze.txt`: Pillow 12.2.0, boto3) |
| Node.js | 24.17.0 |
| Git | 2.54.0 (configurar identidade: `Diogenes Ribeiro` / diogenes.ribeiro@gusto.com) |
| UiPath CLI `uip` | 1.204.0 (`npm i -g @uipath/cli` ou conforme benops-rpa-setup) |
| Plugin Claude | `uipath@uipath-marketplace` 1.204.1 |
| Excel | instalado (necessário para activities de Excel) |
| UiPath Studio + extensão Chrome | extensão instalada como **Current User** |
| PowerShell | 5.1 (pwsh opcional) |

## Passos
1. Instalar ferramentas acima (winget/npm/pip; ver benops-rpa-setup).
2. `git config --global user.name "Diogenes Ribeiro"` e `user.email diogenes.ribeiro@gusto.com`.
3. Clonar `Gusto/biztech-uipath-rpa`; confirmar `develop`.
4. Mapear drives (`network-drives.md`).
5. `uip login`, `uip login status`.
6. Copiar `CLAUDE.md` → `~/.claude/CLAUDE.md`; rodar `restore-memory.ps1`.
7. Instalar plugins/MCPs (benops-rpa-setup) e reautenticar conectores em `/mcp`.
8. Chrome: permitir pop-ups dos carriers quando necessário (ver BT-76973).

## Settings do Claude
`settings.json` atual habilita `uipath@uipath-marketplace` (marketplace local `~/.uipath/.skills`), `tui: fullscreen`, tema `dark-ansi` e um bloco `autoMode` específico deste repo. Recriar com `/config` e `/install-permissions` em vez de copiar.
