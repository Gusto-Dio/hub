---
name: project_bt74316_bcbs_tx_groupsubmissions_cobra
description: "BT-74316 BCBS_TX_GroupSubmissions_NewPlan — fix da Bri (busca de prospect existente antes da BRE de duplicidade) IMPLEMENTADO em NavigateToNewPlans.xaml + ProcessTransaction.xaml (2026-07-23), com placeholders TODO Indicate pendentes de mapeamento ao vivo no Studio Desktop. Retomar 2026-07-24 de manhã: usuário vai indicar os 3 seletores na tela 'Small Group & Middle Market Enrollment' usando o item de teste edc65606-... (fila Benefits, Staging), breakpoint antes do Click_4 em NavigateToNewPlans.xaml."
metadata: 
  node_type: memory
  type: project
  originSessionId: f0056cd1-18c8-4221-9a65-cf0f45da71e8
  modified: 2026-07-23T20:53:31.559Z
---

BT-74316 (Task, prioridade Jira **High**, reportado por Bri Boyer 2026-07-15) — `BCBS_TX_GroupSubmissions_NewPlan`, 2 problemas:
1. Guard "Portal application already started" falha pedidos mesmo quando a tentativa anterior não salvou nada no portal.
2. Na maioria desses casos, a tentativa original não passou da pergunta "Is Group subject to COBRA?" na tela Account Information.

## Status Jira (checado 2026-07-22)
- Assignee: **Diógenes Ribeiro** (antes não tinha)
- Status: **"Under investigation"** (antes "Scheduled"/não pego)
- Priority (campo real): **High** (antes estava "Low" no campo apesar do texto dizer "med/high")
- Sem comentários novos desde o bot de 2026-07-16
- Não está na planilha BenOps de tracking (últimas entradas de maio/2026 — ticket é de julho, fora do range) → `_sheets_not_found = true`, Status/Dev Start Date precisam ser atualizados manualmente se for pra registrar lá

## Causa raiz — revalidada ao vivo em 2026-07-22 (Production)

**Job Faulted mais recente, não coberto pela investigação original: `24b2b461-82f0-4148-85fa-b3b6daa5f2ee`, 2026-07-21.**
Mesma transação falhou **3 vezes consecutivas** (11:03, 11:10, 11:17 UTC) com o exato mesmo erro, até o ReFramework abortar com `"The Process has Failed in the Process State for a consecutive number of times equal to 3"` — mais grave do que eu tinha registrado antes (pensava que era isolado/só retry único da fila).

```
Click 'Do you want to purchase COBRA?': Could not find the UI element corresponding to this selector:
<webctrl aaname='Do you want to purchase HCSC Cobra Administration?:' />
in ProcessLayer\EnterCompanyInfo.xaml → Click_13
```

Confirmado no código atual (`EnterCompanyInfo.xaml:349-392`, develop atualizado) — nada mudou desde 16/07:
- `Click_12` "Is group subject COBRA" → clica radio `value='F'` (No), hardcoded
- `Click_13` "Do you want to purchase COBRA?" (aaname real: "Do you want to purchase HCSC Cobra Administration?:") → clica `value='F'`, hardcoded, **imediatamente depois, sem `UiElementExists` entre eles**

Guard também intacto em `ProcessTransaction.xaml:1420-1424` (`If Progress = "PortalApplicationStarted" → Throw BusinessRuleException`), `Progress` setado em `:1438` antes do `EnterCompanyInfo` rodar. A última PR a tocar esse arquivo foi a minha própria BT-74147 (#2928, mergeada) — só adicionou `LogMessage` de rastreabilidade (`LogMessage_BT74147_PT_8` na linha 1439), não mudou essa lógica.

Esse guard continua "queimando" o Owner do `Carrier_Order__c` no Salesforce real — ver [[feedback_salesforce_owner_burn_guard]].

## Fix proposto (ainda não implementado — decisão de escopo pendente)
- **Seletor (causa raiz do abort):** envolver `Click_13` num `UiElementExists` com timeout curto; pular se não existir em vez de assumir que sempre está lá.
- **Guard (pedido real da Bri):** antes de setar `Progress="PortalApplicationStarted"`, buscar prospects existentes no portal ("Small Group & Middle Market Enrollment" search). Se 0 resultados, seguro reprocessar mesmo com `Progress` já `"PortalApplicationStarted"` de tentativa anterior; só lançar a BRE de duplicidade se a busca achar app/prospect já salvo.

Apresentei as duas opções pro usuário (fix completo vs. só seletor vs. inspeção ao vivo do portal primeiro) — ele pediu para pausar antes de decidir e **tentar reproduzir o erro manualmente ele mesmo**.

## Estado em 2026-07-22 (fim de sessão)
- Nenhuma edição de código feita.
- Nenhuma branch nova criada ainda — ainda estava na branch `BT-74278-...` (ticket diferente); branch `BT-74316-...` precisa ser criada a partir de `origin/develop` antes de qualquer edição de XAML (há mudanças não commitadas em arquivos Anthem_CO/UHC de outras sessões no working tree — checar `git status` antes de criar a branch).
- **Usuário vai tentar simular/reproduzir o erro manualmente** (provavelmente no Studio Desktop ou no portal) antes da próxima sessão.
- **Retomar em 2026-07-23**: perguntar o que o usuário descobriu na simulação manual, e então decidir escopo (seletor só vs. seletor + guard) antes de implementar.

## Sessão 2026-07-22 (continuação) — branch criada, root cause reconfirmada, debug ao vivo pausado a meio

**Branch:** `BT-74316-BCBS-TX-GroupSubmission-NewPlan-cobra-selector-fix`, criada a partir de `origin/develop` atualizado (fetch feito antes). Antes de criar, havia diff não commitado em 2 arquivos do Anthem_CO (`ProcessTransaction.xaml`, `QuotingLicense&ContractValidation.xaml`, e o untracked `~CompanyInformation.xaml`) sobra de outro ticket em paralelo (BT-74235/BT-74343) — guardado via `git stash push -u -m "WIP Anthem_CO (BT-74235/BT-74343?) - saved before switching to BT-74316"` na branch `BT-74278-...` antes do checkout. **Esse stash ainda não foi recuperado** — lembrar de `git stash list` / `git stash pop` quando voltar a trabalhar no Anthem_CO.

**Discovery do projeto rodado** (não existia `.claude/rules/project-context.md` nem `AGENTS.md` no `BCBS_TX_GroupSubmissions_NewPlan`) — ambos os arquivos foram gerados e salvos.

**Root cause revalidada com o item real da produção** (via `uip or queue-items get-history` + `get --all-fields`, tenant Production):
- Item ancestor `db555781-5471-41d9-8528-47451afda90c` (Key), tentativa original, job `ExecutorJobKey=24b2b461-82f0-4148-85fa-b3b6daa5f2ee`, 2026-07-21 11:16-11:17 UTC.
- Empresa: **"Time Capsule ATX LLC"**, `CarrierOrderID=a0mR700000GG5c1IAD`, `Reference=5e5b3d7f-727d-4110-ab3d-eecd62efdcaa`, `CarrierOrderSubmissionRequestUUID` igual.
- `ProcessingException.Reason`: `Could not find the UI element ... aaname='Do you want to purchase HCSC Cobra Administration?:'` — **closest matches todos ≤48%** ("Terms of Use", "Administrative Contact") → confirma que o campo de fato não existe na tela nesse caso (não é seletor frágil, é elemento condicional ausente).
- SpecificContent completo capturado (todos os campos: AccountNumber, Policies, Owners, BenefitsAdmin, etc. — formato PascalCase nativo da fila, não Salesforce `__c`; diferente do padrão do [[feedback_staging_queue_items]] que é específico de filas alimentadas via Salesforce).
- 2ª tentativa (retry, `RetryNumber=1`) no dia seguinte (2026-07-22) bateu na guard "Portal application already started" — confirma os 2 problemas do ticket são a mesma cadeia causal, não incidentes separados.

**Próximo passo interrompido:** ia criar item de teste equivalente na fila Staging (`BCBS_TX_GroupSubmissions_NewPlan`, folder Benefits) replicando esse `SpecificContent` real, pro usuário debugar ao vivo no Studio (ele mesmo vai rodar, pediu "por etapa"). **Tenant `uip login` já trocado pra Staging** nesta sessão (antes estava Production, default) — cuidado, próxima sessão pode voltar pro default Production sem aviso, sempre confirmar com `uip login status` (ver [[feedback_uip_default_tenant_not_production]]).

## Sessão 2026-07-23 — item de teste criado em Staging (e corrigido)
- `SpecificContent` completo do item ancestor real (`db555781-...`, "Time Capsule ATX LLC") buscado via `uip or queue-items get <key> --folder-path "Benefits" --all-fields` no tenant **Production** (trocado temporariamente via `uip login tenant set`, revertido pra Staging depois — sempre confirmar com `uip login status` antes/depois).
- **Armadilha descoberta:** existem **DUAS filas com o mesmo nome** `BCBS_TX_GroupSubmissions_NewPlan` no Staging, em folders diferentes — objetos de fila totalmente distintos, não a mesma fila compartilhada:
  - `Benefits` (folder Id `48382`) → Queue Key `82215f94-3ff0-4215-a357-36ca4bd9b49b`, Id `455682` — **é essa que o processo usa** (job roda com `organizationUnitId: 48382` = `Benefits`).
  - `Benefits/CarrierAutomation` (folder Id `946022`, `ParentID: 48382`) → Queue Key `eb1a6e1f-8d41-4f25-9534-35aa7ea91f56`, Id `455681` — fila errada, não usada por esse processo.
  - 1ª tentativa: criei o item na fila errada (`CarrierAutomation`) → Studio rodou, logou com sucesso no portal, mas deu `"No Transaction Data"` no `GetTransactionData` (folder context mismatch). Item errado (`bc9ddf8b-...`) foi deletado (soft-delete).
  - 2ª tentativa (correta): item criado na fila de `Benefits` direto — **Key `ad27d913-5c84-4bd8-af67-0e0cb0248ca5`**, Reference `BT-74316-STAGING-TEST-benefits-1`.
- `SpecificContent` idêntico ao real, exceto `CompanyName` (sufixo "(BT-74316 STAGING TEST)") e `CarrierOrderSubmissionRequestUUID` (sufixo "-STAGINGTEST") pra não confundir com dado de produção.
- JSON do `--specific-content` passado via arquivo no scratchpad + `$(cat arquivo)` no Bash, técnica de [[feedback_uip_cli_json]].
- **Lição geral (vale para outros carriers/processos):** ao criar item de teste em Staging, sempre confirmar o `organizationUnitId` do job/processo contra o `Id` real do folder via `uip or folders get "<path>"` — nome de fila igual não garante mesmo folder/Queue Key. Path na CLAUDE.md ("Benefits/CarrierAutomation") pode não bater com o folder real onde o processo específico está publicado.

## Sessão 2026-07-23 (continuação) — casing do SpecificContent
- 2ª tentativa (`ad27d913-...`) achou o item, mas quebrou em `ProcessTransaction.xaml:419` (`Assign Transaction values`): `Can not assign 'in_TransactionItem.SpecificContent("carrierOrderID").ToString' to 'carrierOrderID'` — o workflow lê **camelCase** (`carrierOrderID`, `companyName`, `s3Link`, etc; confirmado via grep em `ProcessTransaction.xaml`, ~40 ocorrências, todas camelCase).
- Item `ad27d913-...` (PascalCase) deletado. Item novo **`3eb2b072-4562-4c4f-9c6a-6966f5d31c4b`** criado com `--specific-content` em camelCase (baseado no `SpecificData.DynamicProperties` do item real de produção, que já vinha camelCase).
- **Descoberta importante sobre a CLI/API:** o campo `SpecificContent` no output de `queue-items get`/`add` **sempre mostra PascalCase**, independente do casing enviado — é só normalização cosmética da API/CLI pra exibição. O dado real fica em `SpecificData.DynamicProperties` (string JSON), que preserva o casing original enviado. Pra confirmar o casing real de um item, sempre checar `SpecificData`, nunca confiar no `SpecificContent` do output.
- Atualiza [[feedback_staging_queue_items]]: aquela memória dizia "sempre formato Salesforce, nunca camelCase da CLI" — mas isso é específico de filas alimentadas via Salesforce/dispatcher com Apex (`Group_Number__c`). Filas alimentadas por dispatcher Python/API direto (como essa BCBS_TX) usam camelCase nativo. **Regra geral correta: sempre inspecionar o `SpecificData` de um item real da fila em produção antes de criar item de teste — não assumir um padrão fixo de casing entre filas diferentes.**

## Sessão 2026-07-23 (continuação 3) — decisão de escopo e implementação do fix da Bri

Usuário decidiu: implementar **só** o fix da Bri (busca de prospect existente antes da BRE de duplicidade). O fix do seletor do COBRA (`Click_13` em `EnterCompanyInfo.xaml`) continua **pendente, fora de escopo desta rodada**.

**Plano aprovado via EnterPlanMode** (arquivo `C:\Users\diogenesribei_gsto\.claude\plans\dapper-doodling-brook.md`). Explorei reuso primeiro: `Libraries/Gusto_Benefits/BCBS_TX/Generic/SearchForGroupBCBSTX.xaml` já tem o padrão idiomático (While pollando 2 `UiElementExists` — resultado encontrado vs "No results found." — depois `If Not found Then Throw BRE`), mas é pra um portal DIFERENTE (BAE — Blue Access for Employers, busca de grupo já existente) — não reutilizável diretamente, só como referência de padrão (confirma que a abordagem escolhida é consistente com a convenção do codebase).

**Implementado (não commitado ainda):**
- `NavigateToNewPlans.xaml`: novos args `in_CheckForExistingProspect` (Boolean), `in_CompanyName` (String), `out_ProspectFound` (Boolean). Bloco de busca (TypeInto → Click → While com 2 `UiElementExists` "Prospect Found In Results"/"No Prospect Found") inserido entre `Click_3` ("Small Group & Middle Market Enrollment") e `Click_4` ("Start SG Enrollment without Quote"), gated por `in_CheckForExistingProspect`. `Click_4` só dispara se `out_ProspectFound = False`. As 3 activities novas têm seletor placeholder + `DisplayName="TODO Indicate — ..."` (Placeholder-Selector Stub Pattern — ainda não indicadas ao vivo).
- `ProcessTransaction.xaml`: guard de `Progress = "PortalApplicationStarted"` (linha ~1420) agora invoca `NavigateToNewPlans` com `in_CheckForExistingProspect=True` primeiro; só lança a BRE de duplicidade se `out_ProspectFound = True`; senão loga e segue pro `EnterCompanyInfo` sem re-navegar. Guard de `"PortalApplicationCompleted"` intocado. Caminho de 1ª tentativa (Assign/SetTransactionProgress/Invoke NavigateToNewPlans com `in_CheckForExistingProspect=False`) ficou dentro de um `If Progress <> "PortalApplicationStarted"`, idêntico ao original.
- `validate` limpo nos 2 arquivos. `uip rpa build` do projeto **já falhava antes da minha edição** (confirmado via `git stash` + build limpo contra `develop`) — ~8 grupos de `UI-DBP-006`/`ST-SEC-008` pré-existentes em activities antigas (seletor top-level fora de `BrowserScope`), débito técnico antigo do projeto, não-relacionado. Minhas 2 novas activities só somam ao mesmo padrão pré-existente, não introduzem categoria nova.

**Descoberta nova: `CheckData.xaml:203` valida o `CarrierOrderID` no Salesforce** (`Throw BusinessRuleException("Order is no longer in Automation Queue")`) **antes** de qualquer navegação — item de teste com `CarrierOrderID` real já processado (o "Time Capsule ATX LLC" de antes) falha aqui, nunca chega em `NavigateToNewPlans`. Fix: usar um `CarrierOrderID` de um pedido **ainda `New`/não processado** em Produção (só leitura, nunca acionado).

**Item real usado pra mapeamento:** "Limelight Enterprises LLC", `CarrierOrderID=a0mR700000FJPuwIAH`, `Key=d1f8cc01-0d06-43bd-876a-73b3165b451c` (ainda `New` em Produção, não tocado). `SpecificContent` replicado sem alterações (camelCase, idêntico ao real) em Staging:
- 1ª cópia `b8ea39f7-6d06-4e14-a189-7ddbc6817a8e` — ficou `InProgress`/`Progress=PortalApplicationStarted` (usuário rodou no Studio Desktop, parou no breakpoint antes do `Click_4`; sessão ficou pendurada quando parou pro dia). Não foi limpo — sem urgência, é só bookkeeping de teste.
- **2ª cópia (fresca, pronta pra usar) `edc65606-ac0a-4878-bbfe-c72b1cfdb9ee`**, Status `New`, fila `Benefits` (Staging).

**Risco identificado e confirmado com o usuário antes de agir:** não existe portal de teste separado — rodar esse fluxo loga no BCBS TX real e usa dados reais desse cliente. Mitigação: breakpoint **antes** do `Click_4`, nunca deixar avançar pra `EnterCompanyInfo`/submissão real. Usuário confirmou explicitamente antes de eu criar o item e rodar.

**Limitação confirmada de novo:** `uip rpa debug start` (Helm/headless) não resolve `GetRobotCredential`/`Credential_BCBS_TX` sem folder binding → erro 1101 "A folder is required" — mesma limitação de [[feedback_local_debug_folder_binding]]. Debug **precisa ser no Studio Desktop**, não via CLI headless.

## Sessão 2026-07-23 (continuação 4) — seletores mapeados via HTML real, fix do COBRA implementado, PR #2961 aberta

**Mapeamento dos 3 seletores placeholder do `NavigateToNewPlans.xaml`** feito a partir de HTML real salvo pelo usuário (não Indicate ao vivo) — usuário buscou manualmente por "Limelight Enterprises LLC" (achou) e por uma empresa nova (não achou) na tela "Small Group & Middle Market Enrollment", salvou as duas páginas resultantes:
- Campo de busca: `<webctrl tag='INPUT' id='accountName' />` (label "Account Name")
- Botão buscar: `<webctrl tag='A' id='searchaccount' />`
- Achou: existe `<table id='searchaccresults'>` com linhas de resultado
- Não achou: existe `<li class="ERROR" errortype="backend">No results found.</li>`, sem a tabela

**Fix do seletor COBRA (`Click_13`, `EnterCompanyInfo.xaml`) implementado nesta sessão** (usuário decidiu incluir depois de reproduzir o erro ao vivo): `Click_13` envolvido em `UiElementExists` (seletor **idêntico** ao do click, não só o label) + `If`/`Else` (loga e segue se não existir) + `Delay` de 5s antes da checagem.

**Lição importante (guardar para outros fixes de seletor condicional):** primeira tentativa do fix usou `UiElementExists` só com o label (`aaname='Do you want to purchase HCSC Cobra Administration?:'`), sem a cadeia completa (`nav up='2'` + radio). Deu **falso positivo** (`Exists=True`) mesmo com o elemento realmente ausente da tela (confirmado: não era race condition de navegação, mesma página, sem transição) — suspeita forte é fuzzy-match do `UiElementExists` aceitando um score baixo (ex: 48%, mesmo score dos "closest matches" que apareciam no erro do `Click`) como "existe". **Regra geral: ao envolver um Click condicional num `UiElementExists`, usar a seletor COMPLETA idêntica à do Click (não só o label/elemento pai), senão o check pode dar falso positivo.**

**Erro de dado de teste identificado e corrigido:** ao criar item de teste, sufixei `CompanyName` com `" (BT-74316 STAGING TEST)"` pra diferenciar de dado real — isso quebrou uma validação real do portal (`Legal name cannot be longer than 45 characters` / `Account name...` / `ERISA Plan Sponsor name...`), porque o nome real já tem 41 caracteres, quase no limite de 45. O portal recusou o Continue silenciosamente (ficou na mesma página com alerta), e o bot seguiu adiante como se tivesse navegado, causando erro de `Select Item 'Current Health Carrier'` (campo de tela seguinte que nunca carregou). **Lição: nunca sufixar `CompanyName` (ou outro campo de texto) em dado de teste sem checar limite de caracteres do campo real no portal — usar sufixo em outro campo sem limite apertado (ex: UUID) para identificação.**

**Itens de teste em Staging (fila `Benefits`, "New Perspective Counseling Services, PLLC", `CarrierOrderID=a0mR700000GBP9xIAH`, ainda `New` em Produção):** múltiplas cópias criadas ao longo da sessão (`da7a5557-...`, `bb0b520e-...`, `2074c98a-...`, `8419ce52-...`, `adb2745c-...`, `7d38bd30-...`) — todas ficaram `InProgress`/`Failed` presas em breakpoints de debug sucessivos, sem limpeza (sem urgência, bookkeeping de teste). Última cópia ativa: `7d38bd30-484e-44ff-91be-3e9d9da33ec1` (Status `New`), criada para o usuário deixar falhar de propósito e validar o retry automático (`AcceptAutomaticallyRetry=true`, `MaxNumberOfRetries=1`) — testando o cenário real da Bri (retry com `Progress` já `PortalApplicationStarted`).

**Build do projeto continua falhando** só pela dívida técnica pré-existente (UI-DBP-006 top-level selector fora de `BrowserScope`, ST-SEC-008 SecureString, mais um erro de tooling do analisador `ST-NMG-004` não relacionado) — confirmado de novo que não é regressão nossa. `pack` usado com `--skip-analyze` pra publicar no Staging apesar disso (mesmo padrão de tickets anteriores neste processo, ex: BT-74147).

**Publicado:** v2.0.16 pack + upload + `uip or processes update-version` (processo `55CEFD8F-AAB6-49CF-9058-A1BF7BD2811F`, folder `Benefits`, Staging) — `IsLatestVersion: true` confirmado.

**PR #2961 aberta** (https://github.com/Gusto/biztech-uipath-rpa/pull/2961) contra `develop`, título "[BT-74316] BCBS_TX GroupSubmission NewPlan — fix duplicate-application guard and COBRA question click". Merge de `origin/develop` feito antes do push pra limpar o diff do Buildkite (branch estava desatualizada, `WI_SUI_Audit` aparecia no diff).

## Sessão 2026-07-23 (continuação 5) — commit/push/PR/Staging + fix de dependencylock

Usuário pediu commit + push + publicar no Staging + abrir PR na mesma mensagem. Fluxo executado: commit dos 3 XAML → `git merge origin/develop --no-edit` (limpar diff do Buildkite, branch estava atrás) → push → `pack --skip-analyze` (mesma dívida técnica pré-existente do `build`) → `packages upload` → `processes update-version` no folder `Benefits`/Staging → PR **#2961** aberta via `mcp__githubgusto__create_pull_request`. Comentário simples postado no Jira BT-74316 avisando que o fix da Bri + o fix do COBRA foram implementados na mesma PR.

**Buildkite falhou no primeiro push:** `check_dependency.sh` exigia `Gusto_Benefits 1.553.1` (root `dependencylock.json`), projeto estava em `1.552.8` — mesma causa raiz de [[feedback_check_dependencylock_before_pr]] (3ª ocorrência, eu não tinha checado antes de abrir a PR). Corrigido via `uip rpa packages install --packages 'id=Gusto_Benefits,version=1.553.1'` (atualiza `project.json` automaticamente), revalidado limpo, `projectVersion` bump 2.0.16→2.0.17, republicado no Staging, commit+push de novo.

**Warning não-crítico durante o pack:** `Gusto_Benefits 1.553.1` declara depender de `UiPath.WebAPI.Activities (= 1.16.2)`, mas o `project.json` do processo fixa `[2.4.0]` — pack resolveu e funcionou mesmo assim, mas fica registrado caso o Buildkite reclame disso numa próxima rodada.

## Pendências (atualizadas 2026-07-23, fim de sessão)
- **Teste E2E completo ainda não feito** — só validado até a tela de Additional Info (busca de prospect + skip do COBRA). Falta rodar até `EnrollEmployee`/`WaiveEmployees`/submissão final.
- Usuário vai deixar o item `7d38bd30-...` falhar de propósito pra testar o retry automático real (Progress já setado) — resultado ainda não visto nesta sessão.
- Recuperar o stash do Anthem_CO quando voltar pro ticket BT-74235/BT-74343 (ainda pendente, mencionado há dias).
- PR #2961 aberta, aguardando confirmação do Buildkite (verde após o fix de dependência) e review/merge.
- Possível segundo aviso do Buildkite sobre `UiPath.WebAPI.Activities` (ver acima) — monitorar próxima rodada.

Related: [[feedback_salesforce_owner_burn_guard]], [[project_bt74147_bcbs_tx_add_dependent]] (mesmo processo, ticket anterior, mergeado), [[feedback_uip_default_tenant_not_production]] (tenant trocado pra Staging nesta sessão), [[project_bt74278_uhc_samx_renewal]] (branch anterior na mesma sessão, tinha o stash do Anthem_CO), [[feedback_local_debug_folder_binding]] (erro 1101 confirmado de novo neste processo).
