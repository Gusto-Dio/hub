---
name: feedback_skill_registry_midsession_lag
description: "Plugin/skill auto-update disparado por comando `uip` no meio da sessão não é reconhecido pela sessão atual — precisa sessão nova"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 4a9b7973-4df1-43b4-9622-72185ffef490
  modified: 2026-09-01T02:52:57.181Z
---

Rodar comandos do CLI `uip` (ex.: `uip login status`) pode disparar um auto-update do plugin `uipath` ("Updating UiPath CLI, tools, and skills to version X.X.x... Update succeeded: N skill(s) refreshed"). Isso atualiza os arquivos das skills no disco (`~/.claude/plugins/cache/uipath-marketplace/uipath/<version>/skills/`), mas o **registro de skills da sessão atual continua com a lista carregada no início da sessão** — invocar a skill via `Skill` tool (ex.: `uipath:uipath-rpa`) retorna `Unknown skill` mesmo que ela exista fisicamente na versão nova.

**Why:** confirmado em 2026-08-10 durante trabalho no [[project_bt74849_beam_nhe_portal_fix]] — a skill `uipath:uipath-rpa` (exigida pelo protocolo XAML Edit não-negociável do CLAUDE.md) falhou com "Unknown skill" nesta sessão, mesmo com o plugin já atualizado pra versão 1.198.1 (`installed_plugins.json` confirmava). A mesma skill funcionava normalmente em sessões abertas depois do auto-update.

**How to apply:** se uma skill do plugin `uipath` falhar com "Unknown skill" no meio de uma sessão onde já rodei `uip` CLI antes, não assumir que está ausente do ambiente. Checar `~/.claude/plugins/installed_plugins.json` pra confirmar a versão instalada; se a versão bater e a skill mesmo assim não for reconhecida, é defasagem de registro da sessão — orientar o usuário a abrir uma sessão nova para aquele edit específico, em vez de tentar contornar o protocolo do CLAUDE.md (que é não-negociável antes de editar XAML).

**2026-09-01, confirmado de novo com [[project_bt75260_bsca_grouplevel_coverageoptions_selector]]:** `claude plugins details uipath@uipath-marketplace` é o jeito rápido de confirmar que o plugin está instalado E lista a skill `uipath-rpa` no manifesto (Skills (26) inclui `uipath-rpa`), mesmo que o `Skill` tool ainda retorne "Unknown skill" na sessão atual — separa claramente "plugin ausente" (aí sim precisa `claude plugins install`) de "lag de registro" (só precisa sessão nova). Nesse mesmo evento, `claude plugins update benops-rpa@benops-rpa-skills` falhou com "Plugin is not installed" — importante não confundir os dois plugins (`uipath` e `benops-rpa` são independentes; um pode estar instalado e defasado enquanto o outro nunca foi instalado).
