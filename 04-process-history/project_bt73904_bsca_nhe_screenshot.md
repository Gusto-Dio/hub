---
name: project_bt73904_bsca_nhe_screenshot
description: "BT-73904 — BSCA_NewHireEnrollment não anexava screenshot no erro \"payroll report required\" (regressão da BT-73387)"
metadata: 
  node_type: memory
  type: project
  originSessionId: a75c34b6-0c48-41ed-82ae-039d50a60c8c
---

Ticket: reclamação da Tammy Borders (BenOps) — casos que falham com a mensagem "BSCA portal requires a payroll report..." (adicionada na BT-73387) não têm nenhum screenshot anexado pra ela auditar a falha.

**Root cause:** o guard `screenshotAlreadyTaken=True` (criado na BT-73387 pra evitar que o catch externo tirasse um screenshot em branco pós-reset) também bloqueava o único `UploadStorageFile` existente pra esse cenário — que ficava dentro do bloco gateado por `Not screenshotAlreadyTaken` no catch externo. O screenshot era tirado, salvo local, e apagado sem nunca subir pro bucket.

**Fix (PR #2902, branch `BT-73904-BSCA-NewHireEnrollment-payroll-exception-screenshot-upload`):** adicionado `UploadStorageFile`+`Delete` direto no branch da exceção (`ProcessTransaction.xaml`, `Sequence_BSCAPayrollException`), + `LogMessage` após captura e após upload (pedido do usuário pra facilitar investigação futura). v7.0.2 → v7.0.4.

**Testado:** 2x em Staging via Studio Desktop debug (não via `uip or jobs start` — ver [[feedback_local_debug_folder_binding]] e [[feedback_staging_robot_missing_pillow]]), caso sintético "Gareth Blackwood" (referência `500RBT73904TESTNEW01`, queue `BSCA_NewHireEnrollment`/Benefits). Ambas confirmaram screenshot subindo pro bucket `Transactional Screenshots` em `/{ItemKey}/Error.png`.

**Review fresh-eyes (2026-07-06):** apontou que `UploadStorageFile` sem tratamento de erro mascararia a `BusinessRuleException` de negócio se o upload falhasse (rede/credencial/bucket). Corrigido: envolvido em `TryCatch` que loga warning e continua sem mascarar o erro principal. Commit `dc580196e`.

**Buildkite:** `check_dependency.sh` falhou pedindo `Gusto_Benefits` 1.552.8 — o `project.json` do processo estava em 1.551.1, defasado do `dependencylock.json` do `develop` (bump veio de outro PR não relacionado, mergeado antes da minha branch ser criada). Corrigido alinhando a versão. Ver [[feedback_language_jira_prs]] pra outras regras de PR; considerar checar `dependencylock.json` vs `project.json` ANTES de abrir PR em processos que não são tocados há um tempo, não só depois do erro no CI.

**Status:** PR #2902 aberta ✅, v7.0.5 publicada em Staging (2026-07-07). Comentário amigável (não-técnico) postado no Jira BT-73904 explicando o fix pro usuário; resposta técnica postada no comentário do fresh-eyes na PR. Falta: novo teste em Staging da v7.0.5 (opcional) + review/merge.

**Why relevante:** este mesmo padrão (guard de screenshot duplicado bloqueando upload) pode existir em outros processos com lógica similar de "screenshotAlreadyTaken" — vale checar se outros catches customizados têm o mesmo bug antes de assumir que só esse caso existia.
