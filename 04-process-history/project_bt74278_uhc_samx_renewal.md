---
name: project_bt74278_uhc_samx_renewal
description: "BT-74278 UHC_SamX_GroupSubmissions_Renewal_Modern — PR #2949 ABERTA ✅ (2026-07-21), 3 fixes commitados (15b8c062c2) + merge develop, sem menção de transações no corpo a pedido do usuário. Staging já roda v1.3.11 (idêntica ao PR) desde 2026-07-20."
metadata: 
  node_type: memory
  type: project
  originSessionId: f0056cd1-18c8-4221-9a65-cf0f45da71e8
  modified: 2026-07-21T20:57:59.544Z
---

BT-74278 (Task, Medium priority, reportado por Bri Boyer 2026-07-14, atribuído a Diogenes, status Jira "In Progress") — `UHC_SamX_GroupSubmissions_Renewal_Modern` com spike de erros de negócio: 12 "No alternate plans available" em 5 dias, -12.4% na taxa de sucesso do UHC. Também "Unable to find plan to add on carrier portal".

**Sessão anterior (2026-07-14/15) investigou isso e concluiu algo parecido, mas a memória correspondente nunca foi persistida (arquivo referenciado no MEMORY.md não existia) — perdemos o achado e tivemos que reinvestigar do zero em 2026-07-16.** Esta memória existe justamente para não repetir essa perda.

## Três causas raiz confirmadas (2026-07-16), nenhuma corrigida ainda

**1. "No alternate plans available. Please shop for additional plans."** — `ReviewRenewingPlans.xaml`
- `NCheckState_1` "Check App State 'View Alternatives'" (linha ~242): se não achar o elemento, clica em "Review" (aaname='2') **uma única vez, sem re-checar depois** se a página realmente transicionou pro estado `reviewDetail`.
- Na sequência, `NExtractData_3` "Extract Table Data" (linha ~343) extrai `dtCurrentlySelectedPlans` assumindo que já está na tela certa. Se o clique não completou a navegação (ex: renovação retomada que ainda precisa de "enrollment review", conforme a Bri descreveu), a extração vem vazia/incompleta.
- `MultipleAssign_1` "Get Plans To Be Removed/Added" (linha ~370) calcula `plansToBeAdded` a partir de `currentlySelectedPlans` (vindo da extração) vs `in_SelectedPlanIds` (arg de entrada). Se a extração veio errada, `plansToBeAdded` vem não-vazio incorretamente.
- `If_1` "If there are plans to be added" (linha ~491, `plansToBeAdded.Count>0`) → tenta achar "View Alternatives" pra clicar; se não achar (linha ~530-536) → `Throw BusinessRuleException("No alternate plans available...")`.
- **Confirmado com exemplo real:** item `a0mR700000Ff537IAB`, `Order_Assignment__c = "Same Carrier, NO Plan/Group Level Changes"` — pedido que por definição não deveria precisar de troca de plano nenhuma, e mesmo assim caiu nesse erro.

**2. "Unable to find plan to add on carrier portal"** — mesmo arquivo, linha ~680-697
- Depois de digitar o código do plano na busca (`NTypeInto`), `NCheckState_6` "Check App State 'Plan Checkbox'" tem **Timeout=0.5s** — curto demais se o dropdown/checkbox do portal renderizar devagar. Sem retry (reclicar a busca). Bate exatamente com a suspeita da própria Bri no ticket.

**3. Achado extra, não reportado pela Bri, mas mais grave** — `Main.xaml:690`
- Toda vez que o ReFramework aborta por 3 erros de sistema consecutivos, o próprio Throw de abort quebra: `Config("ConsecutiveErrors")` (chave plana) vs `Data/Config.json` que guarda a chave aninhada em `Config("Exceptions")("ConsecutiveErrors")`. Resultado: `KeyNotFoundException: 'ConsecutiveErrors' was not present in the dictionary` mascara o erro real em quase toda run que faulta (confirmado em 07-14, 07-13, 07-10, 07-08, 07-07, 07-06, 07-03, 07-02, 07-01, 06-29 via `uip or jobs list`).

## Fix proposto (nenhum implementado ainda)
- **1:** depois do clique em "Review", confirmar (retry/verify loop) que realmente chegou no estado `reviewDetail`/"View Alternatives"-elegível antes de extrair — não confiar em clique único.
- **2:** aumentar timeout do `NCheckState_6` e/ou adicionar um retry (reclicar a busca) antes de lançar a exceção.
- **3:** trivial — trocar `Config("ConsecutiveErrors")` por `Config("Exceptions")("ConsecutiveErrors")` em `Main.xaml:690`. Mais simples, mais seguro, vale fazer independente dos outros dois.

Todas as três são fixes só no processo (nenhuma Library tocada).

## Estado da branch (2026-07-16)
Branch `BT-74278-UHC-SamX-GroupSubmission-Renewal-alternate-plans-fix` **já existe**, criada 2026-07-15. Confirmado via `git merge-base origin/develop <branch>` que ela está 100% em dia com `origin/develop` e **sem nenhum commit próprio** — foi criada mas nada foi implementado nela ainda (bate com "pausado a pedido do usuário" da sessão anterior).

**Cuidado:** a `develop` local estava desatualizada (sem `git fetch`) quando comparei — isso gerou um diff falso enorme (29 arquivos não relacionados) até eu fazer `git fetch origin develop` e comparar contra `origin/develop`. Sempre fetch antes de julgar se uma branch tem trabalho pendente.

Nota lateral: na branch atual usada nessa sessão (`BT-74235-...`) havia um diff não-commitado no `Main.xaml` do `UHC_SamX_Renewal_Modern` — mas é só ruído de `HintSize` (abrir no Studio Designer), sem mudança funcional. Usuário decidiu deixar como está por enquanto (não descartar ainda).

## Item de teste em Staging (2026-07-16)
Criado na fila `UHC_SAMx_GroupSubmissions_Renewal` (Staging, folder `Benefits`, queue key `e3cd91c2-f885-41db-941d-6726c138f439`), replicando o `SpecificData` real do item `a0mR700000Ff537IAB` (formato Salesforce com underscore preservado, ex: `Group_Number__c`, `Order_Assignment__c`):
- **Id:** 2474694984
- **Reference:** `a0mR700000Ff537IAB-BT74278-retest`
- **Key:** `c5c1d3a4-1730-4d9e-a290-4a06f3ff6afd`
- **Status:** New

**Nota:** essa fila em Staging tem `MaxNumberOfRetries=1` + `AcceptAutomaticallyRetry=true` (diferente da Production, que tem retry=0) — se o item falhar, pode reprocessar automaticamente sozinho.

## Fixes implementados (2026-07-21, ainda não commitados)
Confirmado via `git diff` no branch que os 3 fixes propostos já foram codados (não commitados ainda):
- **Fix #1** (`ReviewRenewingPlans.xaml`): novo `NCheckState_13` "Check App State 'Plan Cards Loaded'" — checa `BrowserURL=".../reviewDetail"` + seletor `class='planCards'` antes de seguir; se não achar, `Throw BusinessRuleException("Unable to load renewal review screen after clicking Review")` em vez de seguir com extração vazia.
- **Fix #2** (`ReviewRenewingPlans.xaml`, `NCheckState_6` "Plan Checkbox"): `Timeout` 0.5s→5s + bloco de retry completo (redigita o código do plano com `NTypeInto_2` e re-checa com `NCheckState_12`) antes de lançar `"Unable to find plan to add on carrier portal"`.
- **Fix #3** (`Data/Config.json`): `ConsecutiveErrors` promovido pra chave plana (removido o nível `"Exceptions"` aninhado) — resolve o `KeyNotFoundException` que mascarava o erro real no abort do ReFramework. `Main.xaml` já lia a chave plana, então só o Config.json precisou mudar.
- `project.json`: bump 1.3.10 → 1.3.11.
- `Main.xaml`: diff restante é só ruído de HintSize/posição de shapes (abrir no Designer), sem mudança funcional.

**Nenhum commit feito ainda** — está tudo como working tree changes no branch `BT-74278-UHC-SamX-GroupSubmission-Renewal-alternate-plans-fix`.

## Novos itens de teste em Staging (2026-07-21)
Pra validar os fixes #1 e #2 ao vivo no Studio, criados 2 novos itens replicando `SpecificData.DynamicProperties` real de falhas recentes em Production (queue `UHC_SAMx_GroupSubmissions_Renewal`, Production folder `Benefits`, queue key `0cf73cda-14b0-4d50-a891-9d3362ec656d`), na fila Staging (`Benefits`, queue key `e3cd91c2-f885-41db-941d-6726c138f439`):

1. **Fix #1 — "No alternate plans available"** (24 ocorrências nas últimas 100 falhas da fila, replicando `Order_Assignment__c="Same Carrier, NO Plan/Group Level Changes"`, o mesmo padrão do exemplo original `a0mR700000Ff537IAB`):
   - Origem real: `a0mR700000FkZOoIAN` (Production, falhou 2026-07-14)
   - **Id Staging:** 2491454889, **Key:** `58eb2747-307b-4b60-8ba5-c5bd9091910d`, **Reference:** `a0mR700000FkZOoIAN-BT74278-retest-noaltplans`, Status New

2. **Fix #2 — "Unable to find plan to add on carrier portal"** (16 ocorrências nas últimas 100 falhas):
   - Origem real: `a0mR700000FpjaMIAR` (Production, falhou 2026-07-21 hoje mesmo)
   - **Id Staging:** 2491455503, **Key:** `e223e90c-f0b7-430f-9030-47054dcfb113`, **Reference:** `a0mR700000FpjaMIAR-BT74278-retest-planadd`, Status New

Ambos com `SpecificData` verificado pós-criação (raw `Group_Number__c`, `Order_Assignment__c` etc. corretos — não usei o `SpecificContent` cosmético do `get`, seguindo [[feedback_staging_queue_items]]).

Item de teste anterior (Id 2474694984, `a0mR700000Ff537IAB-BT74278-retest`) ainda está `New`/pendente na fila — não foi consumido ainda.

**Nota:** outras 2 causas de falha frequentes na mesma fila, fora do escopo dos 3 fixes: "Policy benefit type is blank or unsupported" (28 ocorrências) e "Could not find the user-interface (UI) element ... Click 'Plan Dropbox'/'Export Summary'/etc" (68 ocorrências, `ApplicationException` — parecem seletores frágeis em telas diferentes do fluxo, não investigado ainda).

## Versão em Staging confirmada (2026-07-21)
`uip or packages versions UHC_SamX_GroupSubmissions_Renewal_Modern` (tenant Staging) mostra **1.3.11** como `IsLatestVersion=true` / `IsActive=true`, publicada por `diogenesribei_gsto` em **2026-07-20T22:06:15Z** — ou seja, o build com os 3 fixes já estava publicado em Staging um dia antes desta sessão, e é exatamente a versão do working tree/PR. Processo bound: `UHC_SamX_GroupSubmissions_Renewal_Modern` (Key `A7C95E6A-767A-4C46-88E5-B583EB13E541`), folder `Benefits`.

**Achado à parte:** o package "UHC_SamX_Renewal_Modern" (sem "GroupSubmissions" no nome) que aparece em `packages list` é um artefato antigo/inativo (versão 1.0.0, 2024-12-30) — nome parecido mas não é o package real usado pelo processo. O package/processo real é `UHC_SamX_GroupSubmissions_Renewal_Modern`. Não confundir os dois ao investigar versões.

## Tentativa de rodar os 2 itens de teste (2026-07-21)
Usuário rodou o processo mas "nenhum estava disponível para processar" — os 2 itens criados (2491454889, 2491455503) continuaram `New`/intocados (`StartProcessing` e `RobotKey` vazios), confirmando que a run não leu da fila Staging `Benefits` onde foram criados (suspeita: `Config.json` tem `QueueFolder: ""` vazio, então depende do folder padrão da conexão Orchestrator do robô/Studio — não investigado a fundo, ficou pendente). Usuário disse que **já validou os fixes em outro contexto** (não detalhado) e decidiu seguir pra PR sem esperar essas 2 transações específicas.

## PR aberta (2026-07-21)
**PR #2949**: https://github.com/Gusto/biztech-uipath-rpa/pull/2949 (branch → `develop`)
- Commit `15b8c062c2` — só os 4 arquivos do ticket (`Config.json`, `Main.xaml`, `ReviewRenewingPlans.xaml`, `project.json`), deixando de fora outras mudanças não-relacionadas que estavam soltas no working tree (Anthem_CO, Guardian, BSCA, `.claude/`, `CLAUDE.md` etc. — múltiplos tickets em paralelo no mesmo checkout).
- Merge commit `2fb451dcdf` de `origin/develop` antes do push, seguindo a Buildkite Rule do CLAUDE.md (branch estava sem fetch há dias, diff mostrava 13 arquivos não-relacionados antes do merge).
- **A pedido explícito do usuário, a PR NÃO menciona transaction IDs** — desvio deliberado do Pre-PR Checklist padrão do CLAUDE.md, não um esquecimento.
- Dependências (`Gusto_Benefits_UHC [1.1.8]`, `Gusto_Benefits_UHC_SAMx 1.0.10`, `Gusto_Modern_Generic 1.3.15`, `Gusto_Modern_Generic_Benefits [1.0.4]`) confirmadas batendo com `origin/develop:dependencylock.json` — sem risco de falha do Buildkite por pin divergente.

## Pendências
- Descobrir por que a fila Staging não entregou os 2 itens de teste na run do usuário (suspeita: `QueueFolder` vazio no Config.json).
- Os 2 itens de teste (2491454889, 2491455503) e o item anterior (2474694984) continuam `New` na fila Staging — não avaliados ainda.
- Causas de falha fora do escopo desta PR, mesma fila: "Policy benefit type is blank or unsupported" (28/100) e seletor frágil em "Click 'Plan Dropbox'/'Export Summary'" (68/100) — candidatas a ticket futuro.

Related: [[project_bt74343_anthem_co_phoneemail_enhancement]] (outro ticket em paralelo na mesma sessão), [[feedback_staging_queue_items]] (formato Salesforce raw pro SpecificContent), [[feedback_uip_cli_json]] (como passar JSON complexo sem word-split/BOM pro `--specific-content`), [[feedback_uip_default_tenant_not_production]] (sempre checar tenant antes de puxar dados).
