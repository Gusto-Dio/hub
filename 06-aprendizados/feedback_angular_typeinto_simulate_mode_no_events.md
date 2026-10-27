---
name: feedback_angular_typeinto_simulate_mode_no_events
description: InteractionMode="Simulate" no NTypeInto/NApplicationCard não dispara eventos keyup/input por caractere — tabelas Angular com busca reativa (ngModel/search-as-you-type) nunca re-filtram, mesmo com o valor certo no campo
metadata:
  type: feedback
  originSessionId: 54ae0ab1-a529-41ce-ae99-64267fd4f71b
  modified: 2026-09-16T20:56:35.825Z
---

Em `Kaiser_GroupSubmissions_MemberLevel_Modern` (BT-75733), o card que digitava no campo de busca da tabela "Manage Members" (Angular SPA) usava `InteractionMode="Simulate"`. Esse modo escreve a string inteira de uma vez no elemento, sem disparar os eventos `keyup`/`input` que o Angular usa para acionar o filtro reativo da tabela. O campo ficava com o valor certo, mas a tabela nunca re-filtrava — toda busca dava resultado vazio (`"Group not in carrier portal"`), mesmo pra grupos confirmados existentes no portal.

**Sinal de diagnóstico:** usuário reportou "quando eu digitei letra a letra manualmente, apareceu" — ou seja, o comportamento manual (eventos reais de teclado) funciona, mas o robô simulando não. Isso é o tell-tale de um componente Angular/React com busca reativa via evento, não polling.

**Fix:** trocar `InteractionMode="Simulate"` → `InteractionMode="DebuggerApi"` (dispara via Chrome DevTools Protocol, eventos reais por caractere). Procurar primeiro se já existe outro card/activity no mesmo workflow usando `DebuggerApi` pra esse mesmo grid — geralmente há um precedente local confirmando que o modo funciona ali.

**How to apply:** sempre que um `Type Into`/`NTypeInto` em SPA (Angular/React) preenche o campo mas a tabela/dropdown/autocomplete nunca reage — mesmo com seletor certo e delay suficiente — suspeitar do `InteractionMode` do card antes de qualquer outra hipótese (dado ruim, portal fora do ar, seletor errado). Relacionado a [[feedback_angular_table_colname_rowname_unreliable]] (mesma classe de problema: robô não interage com Angular do jeito que o framework espera).
