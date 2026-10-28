---
name: feedback_anthem_iframe_html_save_unreliable
description: Salvar a página do portal Anthem (Salesforce Community) como .html não captura o conteúdo do IFRAME — não usar pra inspecionar seletores
metadata: 
  node_type: memory
  type: feedback
  originSessionId: b2a8682d-db14-4bd7-a57e-ba4a3a977eb5
  modified: 2026-08-22T00:28:46.859Z
---

No portal Anthem/Salesforce Community usado pelos processos `Anthem_*_GroupSubmission_*` (páginas "Get a Quote", "EnrollNow" etc.), os campos reais do formulário (OmniScript da Anthem SG Quoting) ficam dentro de um `<webctrl tag='IFRAME' parentid='ServiceCommunityTemplate' />`.

**Why:** "Salvar página como" (Ctrl+S) no Chrome só salva o documento HTML principal da aba — não segue/baixa o conteúdo de iframes cross-origin embutidos. Duas tentativas nessa sessão (`Get a Quote.html` e `EnrollNow.html`) vieram sem nenhum texto dos campos reais (nem "Create a new Group Account", nem "Phone", nem "Email" apareceram no grep do arquivo salvo) — e nenhuma tinha pasta `_files` com o conteúdo do iframe.

**How to apply:** nunca usar um HTML salvo desse portal pra confirmar se um elemento existe ou pra tentar inferir um seletor. Se precisar investigar um seletor/erro nessa área:
1. Pedir screenshot da tela (captura de imagem, não HTML) — ou
2. Rodar `uia-configure-target` com o Studio pausado no breakpoint, ao vivo, apontando pro elemento real — regra do projeto já proíbe inventar seletor sem indicação real.

Related: [[project_bt74235_anthem_co_benefitsadmin]]

**Contraste confirmado (2026-08-21, BT-75006, portal UHC SAMx):** a mesma técnica de "salvar
página" funcionou muito bem lá e resolveu o diagnóstico (achou estado real de checkboxes via
`data-testid`/`checked=""` que o grep encontrou sem problema) — porque o portal SAMx (Abyss
design system, UnitedHealthcare) **não usa iframe** pros campos reais, diferente do Anthem. A
regra não é "nunca confiar em HTML salvo" — é "checar primeiro se há `<iframe>` no arquivo
salvo (`grep -c '<iframe'`) antes de decidir se a técnica serve". Ver
[[feedback_dom_grep_diagnose_missing_element]] pro método completo que funcionou no SAMx.
