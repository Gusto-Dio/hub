---
name: bt76745-oxford-newplan-rating-chip
description: "BT-76745 Oxford_GroupSubmissions_NewPlan — PR #3435 aberta e verde no Buildkite (19/10); chip do rating + Enter Detailed Census opcional; falta publicar 1.55.18 no Staging (Helm exige .NET 10) e FillEmployerApp novo problema"
metadata:
  node_type: memory
  type: project
  originSessionId: 5974d365-6e5f-47be-9c99-6d89516de84d
  modified: 2026-10-19T23:50:19.724Z
---

BT-76745 (Bri, 2026-10-15): Oxford_GroupSubmissions_NewPlan. Problema 1 = "Rating method filter did not apply" (portal mudou o chip para `Rating Method: Composite|Age`, mesmo caso do BT-76184/#3394 do UHC SAMx). Problema 2 = "Error on carrier portal" que na verdade era `Click 'Enter Detailed Census'` sem achar o botão (ProcessTransaction troca qualquer exceção não-BRE por essa mensagem genérica).

**PR #3435 aberta 2026-10-19** (branch `BT-76745-oxford-newplan-rating-chip` → develop, v1.55.18; Prod estava em 1.55.17, Staging em 1.55.15). Buildkite #14904 passou. Só `EnterCompanyInfo.xaml` + `project.json` (Main.xaml/ProcessTransaction.xaml do worktree têm só ruído de layout do Studio, não commitar). Oxford tem `skipTests: update_version, update_dependency`.

Validado no Studio contra Staging (item Anteris, Composite, cópia exata do item de Prod `9112b8f5-...`): chip aplicado na tentativa 1 em 2 execuções, census→plan-shopping sem erro, EnterCompanyInfo OK.

**Ainda aberto:**
- Publicar 1.55.18 no Staging NÃO foi feito: `uip rpa pack` falha porque o Helm 1.203.2 (instalado 14/10) exige .NET 10 e a VDI só tem 8.0.28; `--studio-dir` não ajuda. Precisa instalar .NET 10 runtime ou usar Helm 1.202.1.
- Novo problema, não relacionado: `FillEmployerApp` não acha `innertext='Group Name to appear on ID card*'` (página /enrollment/employer-info carregada, seção General Information com check; campo provavelmente abaixo/recolhido). Nenhum job de Prod chegou nesse passo ainda. Precisa DOM da página.
- Item Rollout `37895d84-...` falha no CheckData ("Order is no longer in Automation Queue"): order não está pronta no SFDC de Staging.

**Why:** itens de Prod copiados pro Staging só passam o CheckData se a Carrier_Order__c existir no SFDC de Staging com Owner "Automation Queue" e stage "Ready for Submission Prep" (QueueItemRecreator só copia itens de fila, não mexe em SFDC).
**How to apply:** relacionado [[project_bt76044_uhc_census_ancillary_columns]], [[project_bt75952_oxford_groupsubmissions_newplan_fix]], [[feedback_test_data_must_be_real_not_borrowed]].
