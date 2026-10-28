---
name: project-bt76427-bcbs-tx-memberlevel-modern-account-details-retry
description: "BT-76427 BCBS_TX_GroupSubmissions_MemberLevel_Modern — retry+F5 no Get Text 'Contact'; PR #3399 aberta (07/10), pacote 2.1.7 em Staging; falta merge, confirmar Prod e SFDC session"
metadata:
  node_type: memory
  type: project
  originSessionId: 8c1660af-cbd0-46d4-9fa4-8e1478bd7802
  modified: 2026-10-07T02:56:36.827Z
---

BT-76427 (aberto 06/10/2026, High, assignee Dio). Process: `Processes/Benefits/CarrierAutomations/GroupSubmission/BCBS_TX/BCBS_TX_GroupSubmissions/` (name `BCBS_TX_GroupSubmissions_MemberLevel_Modern`). Thread Slack #C01CBJW8M16 ts 1791303734.709509.

**Causa raiz:** `Get Text 'Contact'` (CheckGroupBenefits.xaml:273, `tableCol='4'`) falha por erro TRANSITÓRIO do portal (tela de erro ao abrir Account Details), não por mudança de seletor. Jobs diários faulted 09-26→10-06.

**Estado (07/10):** PR #3399 ABERTA (commit 1d487c98ca9, branch `BT-76427-bcbs-tx-membelevel-modern-account-details-retry`). Fix: DoWhile+TryCatch até 3 tentativas em Click Account Summary → Click Account Details → Get Text Contact; catch: Warn + F5 + Delay 5s; 3ª falha = Rethrow. projectVersion 2.1.6→2.1.7. Pacote 2.1.7 subido no feed de Staging (Process NÃO rebindado). Testes Studio/Staging: item real (Group 444821) passou de primeira (retry não disparou); 2ª rodada com `tableCol='99'` forçado, Dio confirmou que o mecanismo funcionou (log não visto por mim). Dio JÁ avisou a Bri (07/10, texto curto em inglês) e vai monitorar execuções após deploy. Dio retoma amanhã (08/10).

**Pendente:** merge da PR → confirmar ProcessVersion/IsLatestVersion em Prod (Buildkite só publica no feed). SFDC `INVALID_SESSION_ID` (~16 min do início do job) NÃO tratado, é issue separada (se cair na lib Gusto_Modern_Generic_Salesforce, decidir à parte). Sheets: BT-76427 não está na aba (tab com espaço à esquerda) — update manual pendente.

**Itens de teste no Staging** (fila BCBS_TX_GroupSubmission_MemberLevel, copiados de itens Failed de Prod com "UI element not found"): Group 444821 (key 72129e3b…, rodou e terminou Failed BusinessException "Automation is not successful for one or multiple EEs" = fluxo normal de EE, não é o bug) e Group 446185 (key b4d6433e…, criado para o teste forçado). Terceiro Failed de Prod: Group 407654. O bot escreve de verdade no Carrier_Order__c do SFDC mesmo em Staging.

**Why:** Fix 2 original (Manual Review) foi DESCARTADO: "Manual Review Required" é flag soft (Process.xaml:974 fecha como Completed e segue), e BusinessRuleException queimaria Owner do Carrier_Order__c. Dio reforçou: não mexer na lógica intencional do Ahsen de retentar o item (ver [[feedback-businessruleexception-gate-is-intentional]]).

**How to apply:** `uip rpa pack` falha neste projeto com 8 erros ST-SEC-008/009 pré-existentes em outros arquivos; usei `--skip-analyze` + `--package-id BCBS_TX_GroupSubmissions_MemberLevel_Modern` para o pacote de Staging ([[feedback-uip-rpa-pack-vs-real-uipcli-analyzer-severity]], [[feedback-uip-rpa-pack-needs-explicit-package-id]]). Ao retomar, conferir `git branch --show-current` ([[feedback-pack-reads-whatever-branch-is-checked-out]]) e rechecar estado da PR antes de pushar ([[feedback-recheck-pr-state-before-pushing-commit]]). Leituras em Prod precisam aprovação explícita e voltar o CLI pra Staging depois ([[feedback-production-reads-blocked-by-auto-mode]]). Não commitar `entry-points.json`/`~Main.xaml` (artefatos do Studio) nem Main.xaml com ruído de re-save.
