---
name: reference-claude-desktop-shortcut-selfheal
description: "Setup do shortcut \"Claude - biztech-uipath-rpa\" na área de trabalho da VDI, com auto-recuperação e ícone customizado"
metadata: 
  node_type: memory
  type: reference
  originSessionId: ada11ec7-bcaa-4ad6-9c71-9a0b6068c186
  modified: 2026-09-22T14:21:36.533Z
---

Shortcut da área de trabalho que abre o Claude Code direto na pasta `U:\Projects\biztech-uipath-rpa` (Windows Terminal via `wt.exe -d "U:\Projects\biztech-uipath-rpa" cmd /k claude`) desapareceu sem deixar rastro (2026-09-22). Causa provável: o Desktop desta VDI (Apporto) é uma pasta redirecionada para rede DFS (`\\gustocloud.apporto\dfs\GSTO\Users\diogenesribei_gsto\Desktop`), e deleções em share de rede não passam pela Lixeira local — some sem histórico. `AppData\Roaming` (Start Menu, Recent) já é local/persistente na VDI, e isso não teve o mesmo problema.

Solução implementada:
- Script `C:\Users\diogenesribei_gsto\AppData\Roaming\ClaudeShortcut\New-ClaudeShortcut.ps1` — recria (só se estiver faltando) o `.lnk` no Desktop **e** uma cópia backup em `Programs` (Start Menu, local), ambos com ícone customizado.
- Ícone gerado localmente (não baixado da internet) via `Make-Icon.ps1` → `claude.ico` (quadrado arredondado laranja/terracota estilo marca Claude + sparkle branco de 4 pontas), salvo na mesma pasta.
- Scheduled Task `RecreateClaudeDesktopShortcut` (trigger AtLogOn) roda o script de recriação a cada login — rede de segurança contra o shortcut se perder de novo.

**Why:** não há Claude Desktop app instalado nem ícone oficial disponível localmente; e o modo automático do Claude Code bloqueia criação de Scheduled Task por padrão (classificado como "Unauthorized Persistence" — [[feedback_scheduled_task_needs_explicit_approval]]), então essa Task só foi criada após aprovação explícita do usuário.

**How to apply:** se o usuário reportar de novo que o shortcut sumiu, ou pedir shortcut parecido pra outra pasta/repo, reusar esse padrão (script + task + ícone gerado localmente) em vez de recriar do zero. Task e script já existem — só checar se ainda estão lá antes de duplicar.
