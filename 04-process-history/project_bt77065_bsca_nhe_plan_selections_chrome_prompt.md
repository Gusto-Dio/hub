---
name: project_bt77065_bsca_nhe_plan_selections_chrome_prompt
description: "BT-77065 BSCA_NewHireEnrollment 'Not successfully navigate to the Plan Selections page' - FIX NO AR em Prod (27/10): lib 1.559.45 (timeout 60s) + processo 7.0.14 rebindado; falta monitorar as próximas rodadas e ler os logs de tempo"
metadata:
  node_type: memory
  type: project
  originSessionId: 49ca5381-00f6-470a-b509-dce9f7b7a4fa
  modified: 2026-10-27T17:56:22.635Z
---

BT-77065 (Tammy Borders, 2026-10-26, "21 in UiPath queue / 48 in SFDC"): BSCA_NewHireEnrollment jobs Faulted daily since 2026-10-22 because the ReFramework aborts after 6 consecutive system exceptions. The bot is NOT dead: most items pass first try; failures are intermittent per item and tend to repeat for the same item (Vanessa 2804911430 failed 4x, ~28 min each).

**Causa (hipótese que virou fix, NÃO provada por log ainda):** o check `UiElementExists 'Plan selections'` na lib `Libraries/Gusto_Benefits/BSCA/NHE/EnterCoverage.xaml` tinha 7s e sem WaitForReady; o portal BSCA (Salesforce OmniScript) é lento e a página estava carregada no screenshot, então falso negativo. O prompt de permissão do Chrome visto nos screenshots antigos nunca foi confirmado como causa. NAV failures (Inactive/cancelled group em NavigateToEnrollment) são caso de negócio que deveria ser BusinessRuleException; NÃO tratado, fica como proposta separada.

**Entregue (27/10):** PR #3594 (lib 1.559.44→1.559.45: timeout 60s + WaitForReady COMPLETE + 2 logs Info com horário "waiting for the Plan selections page, started at HH:mm:ss.fff" / "Plan selections page exists = X at HH:mm:ss.fff"; também alinhou 7 dependências da lib ao dependencylock e bumpou o lock) e PR #3595 (processo 7.0.10→7.0.14, Gusto_Benefits 1.559.45, também bumpou a linha do lock). Ambas mergeadas. Pacotes no feed de Prod; Production Process (folder Benefits, key 15DB87CE-1E09-4FAB-A3FA-6B899F540F97) REBINDADO para 7.0.14 com aprovação explícita do Dio (rollback: `uip or processes update-version <key> --package-version 7.0.10 --folder-path Benefits`). Staging também tem lib 1.559.45 e processo 7.0.14 (7.0.11-13 já existiam lá de testes antigos, por isso 7.0.14). Jira comment 5110261 postado (simples, inglês). Ticket continua aberto para monitoramento.

**Falta:** monitorar as próximas rodadas (trigger 07:10) e ler os dois logs de horário para saber quanto a página realmente demora; item da Vanessa (2806295699, ref 500R700001BJgmhIAD) está `New` na fila Prod. O teste local no Studio da lib 1.559.45 não foi reportado pelo Dio. Risco aceito: lib passou a usar GSuite 3 / Mail 2 / Excel 3 / Generic_Activities 2.2.2 sem validação em execução. Sheet row não existe (aba termina em maio 2026).

**Lições do processo (valem para outros tickets):**
- Desde #3479/#3487 (Thomas Taylor, 26-27/10) `check_dependency.sh` exige que TODO projeto alterado bata exatamente com `dependencylock.json`, sem skip; mexer na lib Gusto_Benefits obriga alinhar todas as suas dependências ao lock. `check_lock.sh` exige o lock com a projectVersion da lib (PR da lib bumpa o lock; PR do processo repete a MESMA linha para passar sozinha, merge limpo).
- Deploy de Prod (`deploy.ps1` via uipcli pack) falhou 2x na lib e 1x no processo com `FileLoadException ... 0x80131509 "operation is not legal in the current state"` (race do analisador/assembly load), sempre no mesmo agente `01a11c2b-78e5-4de3-91b9-5a22aadd8841`; passou no Retry manual seguinte. Falha do processo ANTES da lib estar no feed dá `Cannot create unknown type AddLogFields` (consequência, não bug). Ordem: Retry da lib → conferir feed → Retry do processo. Ver [[feedback_buildkite_analyzer_race_intermittent]].
- Buildkite MCP não tem retry; Dio clica Retry. `uip or packages upload` dá 409 se a versão já existe; subir versão maior em vez de apagar. `uip login tenant set Production` ao terminar com Staging.
- Pack local da lib não valida dependências do feed Orchestrator (uipcli local não acha Gusto_Generic_Activities 2.2.2); PR de branch não empacota, só o deploy no develop acusa.

Ver [[feedback_pr_no_claude_signature_no_tx_table]] (commit sem co-author de IA; tirei o Co-Authored-By e dei force-with-lease na branch nova), [[feedback_uip_libraries_vs_packages_upload]], [[reference_pack_with_uipcli_when_helm_needs_dotnet10]], related BSCA: [[project_bt75792_bsca_navigatetoonlinerenewals_popup_fix]].
