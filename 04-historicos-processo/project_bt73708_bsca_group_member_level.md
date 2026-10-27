---
name: bt73708-bsca-group-member-level
description: "BT-73708 BSCA_GroupSubmissions_MemberLevel — Edit Subscriber click ainda falha intermitente mesmo após scrollIntoView (PR #2883); bypass via navegação direta de URL VALIDADO AO VIVO 2026-07-11 (accountId+recordId da própria URL, sem clicar), ainda não implementado"
metadata: 
  node_type: memory
  type: project
  originSessionId: 119f3cd5-eaa0-402a-9b5c-8e6ac8ebd110
---

## Status atual (2026-07-02)
PR #2883 aberta: https://github.com/Gusto/biztech-uipath-rpa/pull/2883
v6.2.9 publicada e live no Staging (IsLatestVersion: true).
Branch: `BT-73708-BSCA-GroupSubmissions-MemberLevel-edit-subscriber-fix` (mergeada com develop antes do PR).

## Causa raiz confirmada (via git log -p nos commits #2792/#2798)
O clique 'Edit Subscriber' já passou por 3 modos de interação, cada um com falha documentada:
1. `SendWindowMessages` (legacy `ui:Click`) — mandava a mensagem pra coordenada errada, falhava silenciosamente (form nunca abria).
2. `InteractionMode=HardwareEvents` (`uix:NClick`, estado anterior) — escolhido de propósito porque o botão está embrulhado em Lightning Web Components (Salesforce OmniStudio FlexCard) que só aceitam clique com `isTrusted=true`. Mas quebra com "outside of screen bounds" quando o elemento renderiza fora dos limites do monitor (x=2835/4401 observado).
3. **Fix aplicado:** adicionar `Inject Js Script` (mesmo seletor do NClick) imediatamente antes do clique, com `ScriptCode="function(element, input) { element.scrollIntoView(); }"` — rola o elemento pra viewport visível antes do `HardwareEvents` calcular a coordenada. Mantém `HardwareEvents` (precisa do isTrusted).

## Descobertas técnicas (para referência futura)
- Botão real: `<button class="vlocity-btn nds-button nds-button_neutral">` dentro de `<c-button>` → `<c-navigate-action>` → `<vlocity_ins-action>` (Salesforce LWC/OmniStudio FlexCard) com visibilidade condicional via JSON `data-conditions`.
- `NClick.InteractionMode` (enum `NInteractionMode`) valores confirmados via reflection no assembly: `HardwareEvents`, `Simulate`, `WindowMessages`, `Background`, `DebuggerApi`, `Auto`, `SameAsCard`.
- `TryScrollIntoView` **NÃO existe** como propriedade de `TargetAnchorable` (testado, erro de compilação confirmado).
- `NInjectJsScript.ScriptCode` precisa ser uma função anônima completa: `function(element, input) { ... }` — `element` é o nó resolvido pelo seletor do UiPath (atravessa Shadow DOM), `input` vem de `InputParameter`. Referenciar via `arguments[0]` ou `element` bare (sem wrap de função) dá erro. Doc oficial: https://docs.uipath.com/activities/other/latest/ui-automation/inject-js-script
- `.local/docs` do pacote `UiPath.UIAutomation.Activities` **não gera via CLI headless** — só parece funcionar dentro do Studio Desktop real (que também não abre via `uip rpa studio start` nesta VDI: "Studio does not support rpa-tool").

## Bloqueio separado, NÃO relacionado a este fix (achado durante o teste, mas fora do escopo do PR)
Rodando um teste E2E via caso real, bateu em `CensusException: "Census file is not available"` — vem de `ga:GetS3Census` (`ProcessTransaction.xaml`) não achando nenhum objeto no bucket S3 `gusto-uipath-exports-production` com o prefixo `census/biztech/renewal_OE_census/renewal_census_{zpCompanyId}_{Application_Id__c}`. É um problema de dado/export ausente, não de código. Acontece ANTES do fluxo chegar em UpdateEmployeeMedicalBenefits, então não valida o fix do Edit Subscriber em E2E completo ainda — só via debug direto no Studio (que já confirmou o fix funciona).

## Pendências
- [ ] Full E2E via Orchestrator job — pendente (test plan do PR marcado como pendente)
- [ ] Review/merge do PR #2883
- [ ] BT-73708 também mencionava seletor 'Member Roster' quebrado em `UpdateEmployeeDetails.xaml` (closest match 'Member 360' 80%) — **ainda não resolvido**, não fazia parte deste PR.

## Sessão pausada em 2026-07-02
Dio saiu e volta em outra sessão (provavelmente 2026-07-03). Comentário em inglês já postado no Jira BT-73708 avisando fix aplicado + PR aberta + aguardando review. Próximo passo ao retomar: decidir se ataca o seletor 'Member Roster' agora ou espera review do PR #2883 primeiro.

## Novas hipóteses levantadas durante investigação do BT-74168 (2026-07-11) — NADA implementado ainda

O scrollIntoView (#2883) continua não resolvendo 100% — `Click 'Edit Subscriber'` ainda falha intermitentemente em Staging com "verification failed, action did not have the expected outcome" mesmo com o fix aplicado. Duas hipóteses novas, nenhuma testada ainda:

**1. `ClickType="Double"` no `NClick_1`** (`UpdateEmployeeMedicalBenefits.xaml` linha 351) — é o **único** clique duplo em todo o processo (confirmado via grep, todos os outros usam single click). Hipótese: se o botão "Edit Subscriber" funciona como toggle (abre o painel de edição), um duplo-clique pode abrir e fechar no mesmo gesto, resultando em "nada muda visualmente" — bate com a mensagem de erro. Pior: a própria `VerifyOptions Mode="Disappears" Retry="True"` do `NClick`, ao falhar a verificação, re-executa o clique inteiro (outro duplo-clique) — cada retry pode estar se autocancelando de novo. Isso explicaria por que trocar só o modo de interação (`SendWindowMessages`→`HardwareEvents`→`+scrollIntoView`) nunca resolveu: o problema pode não ser COMO o clique é enviado, mas QUANTAS VEZES. Próximo passo: testar `ClickType="Single"` em debug ao vivo antes de commitar.

**2. Bypass do clique via navegação direta de URL.** Clicar em "Edit Subscriber" manualmente leva pra `https://enroll.blueshieldca.com/producer/s/memberlevelchanges?Status=Active&accountId={accountId}&memberid={recordId}`. A página atual "Member 360" (onde o robô já está antes de clicar) **já tem esses mesmos dois IDs na própria URL**, num link interno: `.../s/member-360?recordId={mesmoValor}&accountId={mesmoValor}&Status=Active&SubGroupID=1000&tabset-...`. Ou seja, dá pra ler a URL atual via UI Automation, extrair `recordId`/`accountId`, montar a URL de destino e navegar direto — sem clicar em "Edit Subscriber" nenhuma vez, eliminando o duplo-clique e qualquer instabilidade de interação de uma vez.
- **`accountId`/`memberid` são da org Salesforce da própria Blue Shield (portal), não da Gusto** — IDs de registro Salesforce não são portáveis entre orgs, então não tem como pré-buscar isso via SOQL da Gusto. Só dá pra obter lendo a tela/URL já carregada.
- **Risco não validado:** páginas Salesforce Lightning/Vlocity costumam ser SPA com roteamento client-side — a URL pode mudar via `history.pushState` ao navegar internamente, mas isso não garante que abrir essa URL direto (fora do fluxo normal do app) reconstrua o mesmo estado. Pode dar erro ou redirecionar.
- **Teste barato antes de codar qualquer coisa:** colar a URL de destino direto na barra de endereço (numa aba/sessão onde não se clicou Edit Subscriber antes) e ver se abre normal. Combinado com o usuário, ainda não executado.

Ambas as hipóteses surgiram investigando BT-74168 (que também toca o mesmo arquivo/fluxo de recuperação), ver [[project_bt74168_bsca_member_roster]].

## Bypass via URL — VALIDADO AO VIVO (2026-07-11), ainda não implementado

Testado manualmente e **funcionou**: colando a URL de destino direto na barra de endereço (mesma aba, sessão já logada, sem clicar em "Edit Subscriber"), a tela de edição abriu certinho. Confirma que a Salesforce Lightning/Vlocity aceita deep-link direto pra essa URL — não depende do roteamento interno do clique.

**Dados confirmados ao vivo (não inferidos de HTML salvo):**
- `accountId` — disponível na URL da tela do **grupo/conta**, que o robô já visita (`SearchForGroup`/`NavigateToOnlineRenewals`): `https://enroll.blueshieldca.com/producer/s/account/{accountId}/{nome-slug}?tabset-...` — ex real: `.../s/account/0014O000026zsmTQAQ/coast-creative-llc?tabset-ee9a7=5632d`.
- `recordId` (=`memberid`) — disponível na URL da tela **Member 360** do funcionário específico (onde o robô já está antes de tentar "Edit Subscriber"): `https://enroll.blueshieldca.com/producer/s/member-360?recordId={recordId}&accountId={accountId}&Status=Active&SubGroupID=1000&tabset-...` — ex real confirmada ao vivo: `recordId=a7iNu000001v1I9IAI&accountId=0014O000026zsmTQAQ`.
- **URL de destino testada e validada:** `https://enroll.blueshieldca.com/producer/s/memberlevelchanges?Status=Active&accountId={accountId}&memberid={recordId}` — abriu a tela de edição normalmente.

**Descartado:** o CSV de census baixado (`GetPortalCensus.xaml`, coluna "Member ID" mantida pelo `FilterDataTable` em `ProcessTransaction.xaml:517`) tem um "Member ID" DIFERENTE — é um número de 9 dígitos (ex: `911296720`), identificador de negócio/apólice da Blue Shield, não o ID interno do Salesforce (`a7i...`). Confirmado lendo um CSV real (`W0107631_COAST CREATIVE LLC_Member_Details....csv`). Não serve pra montar a URL.

**Próximo passo (não implementado):** trocar em `UpdateEmployeeMedicalBenefits.xaml` a sequência `NInjectJsScript (scrollIntoView) + NClick_1 (Click 'Edit Subscriber', duplo-clique)` por: (1) ler a URL atual da aba via UI Automation (achar a atividade exata — `NGetFullUrl` ou equivalente, verificar via `activities find`), (2) extrair `recordId`/`accountId` via Regex, (3) montar a URL de destino, (4) navegar direto (Browser Navigate). Precisa também trocar a verificação pós-ação (não faz sentido mais checar "Disappears" do botão — checar algum elemento da tela de destino em vez disso). `accountId` também precisaria ser capturado uma vez (cedo no fluxo, na tela do grupo) e passado como argumento até `UpdateEmployeeMedicalBenefits.xaml` (hoje não é — verificar se já existe alguma variável de conta/grupo disponível nesse nível ou se precisa adicionar argumento novo).

Isso elimina a causa raiz do gatilho mais comum da recuperação do BT-74168 (falha no "Edit Subscriber"), mas não elimina outros gatilhos (ex: "Add dependent") — o fix do BT-74168 (`Click_7`/`Click_8`) continua sendo relevante independentemente.

## IMPLEMENTADO (2026-07-11) — tratado como parte do BT-74168, não PR novo ainda

Usuário decidiu tratar esse bypass como a solução prática do BT-74168 (em vez de separar por ticket), já que elimina o gatilho que joga o processo no caminho de recuperação problemático.

**Mudanças em `UpdateEmployeeMedicalBenefits.xaml`:**
- 4 variáveis novas: `currentPortalUrl`, `bscaRecordId`, `bscaAccountId`, `editSubscriberUrl`.
- Depois do `NInjectJsScript` (scrollIntoView, mantido intocado): `NGetUrl` (pega URL atual) → 2x `Assign` (extrai `recordId`/`accountId` via `Regex.Match(...).Groups(1).Value`) → `Assign` (monta `https://enroll.blueshieldca.com/producer/s/memberlevelchanges?Status=Active&accountId={bscaAccountId}&memberid={bscaRecordId}`) → `NGoToUrl` (navega direto).
- `NClick_1` "Click 'Edit Subscriber'" (duplo-clique) original **movido pro `ui:CommentOut`** já existente no arquivo (não deletado) — IDs renomeados pra `CommentOut_EditSubscriberClick`/`Sequence_EditSubscriberClickIgnored` pra evitar colisão com o `CommentOut_1`/`Sequence_90` vazio que já existia mais abaixo no mesmo arquivo.
- `NGetUrl`/`NGoToUrl` (`UiPath.UIAutomationNext.Activities`) sem docs locais nem bundled no skill — autorado a partir de `get-default-xaml` + exemplos reais de `NGoToUrl` já usados em outros processos do repo (`Kaiser_CA`, `CoveredCal`, `CA_EDD` — só `Url` + `Version="V4"`, sem `ScopeIdentifier`).
- Validação: `uip rpa validate` limpo. `uip rpa build`: 22 erros de analyzer (era 23 antes) — nenhum erro novo, um a menos (o antigo "Click 'Edit Subscriber' used without SimulateClick or SendWindowMessage" não é mais sinalizado por estar comentado).

**Testado no Studio (debug) em 2026-07-11:** usuário confirmou que a etapa funcionou (chegou até a navegação direta com sucesso).

**Teste E2E (2026-07-11, mesmo dia) — FALHOU, causa encontrada e corrigida (não re-testada ainda).** Rodou a transação completa (mesmo caso `a0mR700000Fl838IAB`/COAST CREATIVE LLC). Log mostrou "Clicked on Edit Subscriber bottom" (nosso novo fluxo executou sem erro), mas `RetryScope_2` (6x/6s) nunca achou "member plan modifications" — usuário confirmou visualmente que o botão "Edit Subscriber" ainda estava na tela, ou seja, a navegação NÃO surtiu efeito na aba rastreada.

**Causa provável:** `NApplicationCard_1` ("Chrome Member 360") usa `InteractionMode="DebuggerApi"`, e tanto `NInjectJsScript_1` quanto o `NClick_1` original têm `ScopeIdentifier="b522d21c-2adc-42be-92ce-b55cb04c7211"` explícito (amarrando à mesma instância rastreada do browser). O `NGetUrl`/`NGoToUrl` que adicionei **não tinham esse `ScopeIdentifier`** — hipótese: sem ele, a navegação pode ter acontecido em outra instância/aba (ou não ter sido aplicada à aba certa), enquanto a aba rastreada pela `RetryScope_2` continuou em Member 360.

**Fix aplicado (não re-testado ainda):** adicionado `ScopeIdentifier="b522d21c-2adc-42be-92ce-b55cb04c7211"` em ambos `NGetUrl_1` e `NGoToUrl_1`. `uip rpa validate` aceitou a propriedade (confirma que existe em ambas as atividades). `uip rpa build`: 22 erros de analyzer (igual antes do fix, nenhum novo).

**Nota:** Studio já reformatou o arquivo ao abrir/rodar (revelou defaults antes ocultos: `NInjectJsScript` ganhou `InputParameter="{x:Null}" ScriptOutput="{x:Null}"`; `NGoToUrl` ganhou `DelayAfter="2" DelayBefore="3"`) — normal, não é uma mudança nossa.

**Atualização (mesmo dia, depois do fix do ScopeIdentifier):** usuário confirmou que a navegação por URL FUNCIONOU (não precisa mais tocar nisso). Chegou certinho na tela "MemberLevelChanges" (confirmado por HTML salvo, título + URL com `accountId`/`memberid` corretos). Problema seguinte, DIFERENTE: `RetryScope_2` (que checa "member plan modifications" antes de clicar) deu falso negativo — usuário confirmou visualmente que o botão estava na tela, mas a checagem disse que não.

**Causa encontrada:** `NCheckState_2` usava seletor com `idx='3' src='.../resource/*memberPlanModifications*'` — contei no HTML salvo (`MemberLevelChanges.html`) e existem **4 elementos** IMG que casam com esse padrão genérico, não 3. Como a página agora é alcançada via navegação direta (não mais pelo clique dentro do SPA), a ordem/quantidade desses elementos mudou, e o `idx='3'` não aponta mais pro elemento certo. Esse seletor já era frágil antes (pré-existente, não introduzido pela nossa mudança), só que a troca de navegação expôs o problema.

**Fix aplicado (2026-07-11):** substituí o `NCheckState_2` (moderno, `uix:`, com `idx` frágil) por um `ui:UiElementExists` clássico, reaproveitando o seletor JÁ ESPECÍFICO (sem `idx`, resource ID fixo `1622904730000`) que o `Click_46` "Click 'Member plan modifications'" (imediatamente depois) já usa — ideia do próprio usuário, pra garantir que a checagem e o clique procurem exatamente o mesmo elemento. Lógica de log (`LogMessage_7`/`LogMessage_8`, "appeared"/"not appeared") preservada, só movida pra um `If` normal em vez do `IfExists`/`IfNotExists` do `NCheckState`. `validate` limpo, `build`: 21 erros (era 22, um a menos — nenhum novo).

**CONFIRMADO FUNCIONANDO (2026-07-11) — E2E passou.** Usuário rodou de novo e confirmou sucesso: navegação por URL direta + checagem de "member plan modifications" sem `idx` funcionaram juntas, fluxo completo do "Edit Subscriber" (bypass) passou ponta a ponta em debug no Studio.

**Resumo final do que foi implementado em `UpdateEmployeeMedicalBenefits.xaml` (nada publicado no Staging/PR ainda):**
1. `NClick_1` "Click 'Edit Subscriber'" (duplo-clique, suspeito original) → comentado via `ui:CommentOut` (preservado, não deletado).
2. Novo fluxo no lugar: `NGetUrl` (pega URL atual, com `ScopeIdentifier` da mesma aba) → extrai `recordId`/`accountId` via Regex → monta URL de `memberlevelchanges` → `NGoToUrl` (navega, mesmo `ScopeIdentifier`) — bypassa o clique problemático inteiramente.
3. `NCheckState_2` (seletor `idx='3'` frágil, só 3 de 4 elementos) → substituído por `ui:UiElementExists` clássico reaproveitando o seletor específico (sem `idx`) do `Click_46` seguinte — checagem e clique agora visam o mesmo elemento exato.

**Próximos passos (não feitos ainda):** publicar no Staging, testar 2-3 transações via Orchestrator (não só debug Studio), abrir PR. Decidir se isso fecha o BT-74168 sozinho ou se ainda vale a pena implementar o fix do `Click_7`/`Click_8` (`UpdateEmployeeDetails.xaml`) como reforço pra outros gatilhos (ex: falha no "Add dependent") — ver [[project_bt74168_bsca_member_roster]].

## Padrão recorrente encontrado em MAIS arquivos: NCheckState (uix:) redundante/frágil na mesma tela "MemberLevelChanges"

Depois do fix acima, apareceu o MESMO tipo de problema em `UpdateCoverage.xaml` (`RetryScope_1`, "Retry checking for 'Plan Selection' web state", linha ~275) — mesma tela `enroll.blueshieldca.com/producer/s/memberlevelchanges`. Usuário mesmo aplicou o fix (2026-07-11): comentou o `NCheckState_1` "Check App State 'Plan Selection'" via `ui:CommentOut` (padrão idêntico ao usado em `UpdateEmployeeMedicalBenefits.xaml`).

**Detalhe importante:** aqui o `NCheckState_1` nem controlava a lógica de fato — o `RetryScope_1.Condition` (`CheckTrue`) já usava a variável de um `ui:UiElementExists` clássico PRÉ-EXISTENTE (`planSelections`, `UiElementExists_2`, seletor `aaname='Plan selections'`), não a variável do `NCheckState` (`boolPlanSelection`). O `NCheckState` era puramente informativo (só gerava log) — comentá-lo não muda o comportamento de controle, só remove uma fonte de erro/exceção redundante.

Validado: `uip rpa validate` limpo, `build` com 21 erros (igual antes, nenhum novo).

**Hipótese geral:** esse processo parece ter passado por uma modernização parcial (clássico `ui:Click`/`ui:UiElementExists` → `uix:N*`) em algum momento, deixando MUITOS checks `NCheckState`/`NClick` modernos convivendo com os clássicos equivalentes que já funcionavam — e os modernos (`TargetAnchorable`, capturados num contexto de navegação diferente) são os que estão dando problema agora que mudamos a forma de chegar na página. **Vale a pena varrer os outros arquivos do fluxo pós-"Edit Subscriber" (`UpdateEmployeeDependents.xaml`, resto de `UpdateCoverage.xaml`, etc.) procurando por `uix:NCheckState`/`uix:NClick` que possam ter o mesmo problema, antes de declarar o fix 100% pronto para produção.**

**Ainda pendente:** nada commitado/publicado no Staging ainda. Ver [[project_bt74168_bsca_member_roster]] pra status geral do ticket.
