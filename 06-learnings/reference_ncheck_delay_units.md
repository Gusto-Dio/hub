---
name: reference_ncheck_delay_units
description: uix:NCheck (e outras activities modernas "N*" do UiPath.UIAutomationNext.Activities) usa DelayBefore/DelayAfter em SEGUNDOS, diferente do TypeInto/Click clássico que usa DelayBefore/DelayMS em milissegundos
metadata:
  type: reference
  originSessionId: 64b75f28-88d6-466c-b81c-27e5ff57cf5f
  modified: 2026-08-22T00:28:35.044Z
---

Confirmado empiricamente no BT-75006 (`EnterCompanyInfo.xaml`, `NCheck_4` "Level Funded"):
`DelayBefore="5" DelayAfter="4"` resolveu uma race condition de renderização (a página React/SPA
precisava de alguns segundos pra assentar o estado do toggle mutuamente exclusivo antes do
próximo clique) — 5/4 milissegundos seriam irrisórios pra esse tipo de espera, então a unidade
real é **segundos**.

Isso é diferente do padrão das activities clássicas (`ui:TypeInto`, `ui:Click`) já usadas no
mesmo arquivo, onde `DelayBefore="300"`/`DelayBefore="500"` claramente são **milissegundos**
(300ms, 500ms — típico de pacing entre campos de formulário).

**Como aplicar:** ao adicionar `DelayBefore`/`DelayAfter` numa activity `uix:N*` (namespace
`UiPath.UIAutomationNext.Activities` — NClick, NType, NCheck, NGetText, etc.), usar valores
pequenos em SEGUNDOS (1-5 é razoável pra esperar uma SPA re-renderizar). Nas activities clássicas
(`ui:Click`, `ui:TypeInto`, sem o prefixo `N`), os mesmos nomes de propriedade
(`DelayBefore`/`DelayMS`) são em MILISSEGUNDOS. Não copiar o valor numérico entre as duas
famílias sem converter a unidade.
