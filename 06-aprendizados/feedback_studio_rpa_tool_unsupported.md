---
name: feedback_studio_rpa_tool_unsupported
description: "uip rpa studio start falha na VDI atual — Studio Desktop instalado não suporta rpa-tool, bloqueando focus-activity e breakpoints em activity específica"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: f55fa2fc-cd97-4bc2-bc2f-eea54bd4bdd2
---

`uip rpa studio start --project-dir "<dir>" --output json` retorna `Failure: "Studio  does not support rpa-tool. Please upgrade to the latest version of UiPath Studio."` (checado 2026-07-03, projeto Guardian PacketCollection).

**Why:** a versão do UiPath Studio Desktop instalada na VDI é antiga demais para o `rpa-tool` que o CLI usa internamente. Isso bloqueia qualquer fluxo de debug que dependa de `uip rpa focus-activity` (breakpoint em activity exata, `debug test-activity`, `debug start-from-here`, `debug toggle-breakpoint` direcionado). Fluxos headless (`run`, `debug start` com breakpoint no nível do arquivo inteiro, `debug step-*`, `debug continue`) continuam funcionando via Studio headless (Helm).

**How to apply:**
1. Para debug preciso numa activity específica, ou o usuário conduz manualmente no Studio Desktop (mouse, breakpoint visual), ou considerar atualizar o Studio Desktop instalado na VDI antes de depender de `focus-activity`.
2. Sem `focus-activity`, `debug toggle-breakpoint` só pode ser aplicado no workflow inteiro (pausa na primeira activity do arquivo) — não numa linha específica.
3. Nunca usar `uip rpa run` ou `uip rpa debug start` para testes de ponta-a-ponta que abrem browser/UI — ver [[feedback_orchestrator_job_trigger]] — isso roda local na VDI do dev e disputa a tela ativa. Combinado com essa limitação do Studio, o caminho mais seguro pra evidência ao vivo de bugs de UI é: o usuário conduz o Studio manualmente, ou dispara um job real via `uip or jobs start` no robot de Staging e analisa logs depois.
