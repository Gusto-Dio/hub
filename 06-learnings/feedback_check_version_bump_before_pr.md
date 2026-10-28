---
name: feedback_check_version_bump_before_pr
description: "Buildkite check_version.sh falha com 'process can't be upgraded from version X to X' se o projectVersion do project.json não for bumpado a cada PR"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 321f2707-7d65-498f-b8fa-e36e22470856
  modified: 2026-07-27T22:50:19.289Z
---

Buildkite roda `.buildkite/check_version.sh <process-dir>` em toda PR, comparando o `projectVersion` do `project.json` do processo contra a versão publicada no Orchestrator/develop. Se o processo teve arquivos alterados mas o `projectVersion` ficou igual ao já publicado, falha com `process can't be upgraded from version 1.1.1 to 1.1.1` — mesmo com o merge do develop feito e o `dependencylock.json` em dia (isso é um script diferente do `check_dependency.sh`, ver [[feedback_check_dependencylock_before_pr]]).

**Why:** aconteceu na BT-74498 (PR #2967) — abri a PR com o fix certo mas esqueci de bumpar `projectVersion` em `Anthem_CA_GroupSubmission_NewPlan_Modern/project.json` (ficou "1.1.1" → precisava virar "1.1.2"). Só vi o erro depois do Buildkite já ter rodado e falhado.

**How to apply:** Antes de commitar/push de qualquer XAML de processo, checar e bumpar `projectVersion` no `project.json` do processo tocado (patch bump é suficiente, ex: 1.1.1 → 1.1.2). Fazer isso junto do checklist de `dependencylock.json` — os dois scripts do Buildkite (`check_version.sh` e `check_dependency.sh`) rodam separados e falham por motivos diferentes, então checar um não garante o outro.
