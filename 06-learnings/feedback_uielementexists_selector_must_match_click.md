---
name: feedback_uielementexists_selector_must_match_click
description: "Ao envolver um Click condicional num UiElementExists (padrão 'skip se não existir'), usar a seletor COMPLETA idêntica à do Click, não só o label/elemento pai — senão o Exists pode dar falso positivo por fuzzy-match"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 1966d1d1-b759-4916-95ae-fe62c13a0f05
  modified: 2026-07-23T20:52:50.033Z
---

Ao adicionar um `ui:UiElementExists` para decidir se um `ui:Click` condicional deve disparar (elemento que só aparece em certos estados de tela), usar a **seletor completa e idêntica** à do `Click` real (toda a cadeia — label + `nav`/`parentid` + elemento clicável final), nunca só o label/elemento pai isolado.

**Why:** no BT-74316 (`EnterCompanyInfo.xaml`, campo "Do you want to purchase COBRA?"), a primeira versão do fix usou `UiElementExists` só com o label (`aaname='...'`), sem a cadeia completa (`nav up='2'` + radio input). Isso deu **falso positivo** (`Exists=True`) mesmo com o elemento genuinamente ausente da tela — confirmado ao vivo pelo usuário: não era race condition de navegação (mesma página, sem transição). Causa provável: `UiElementExists` aceita matches de confiança mais baixa (fuzzy) do que `Click`, que exige uma correspondência muito mais próxima antes de agir — o mesmo score baixo (~48%) que aparecia nos "closest matches" do erro do `Click` bastou pro `Exists` considerar "encontrado".

**How to apply:** ao criar esse padrão de guard (`UiElementExists` → `If` → `Click`), sempre copiar a seletor final e completa usada pelo `Click` real pro `Target` do `UiElementExists`, em vez de simplificar pro elemento pai/label. Se o `Click` usa `<webctrl aaname='X' /><nav up='N' /><webctrl tag='INPUT' ... />`, o `Exists` deve usar essa mesma cadeia, não só `<webctrl aaname='X' />`.
