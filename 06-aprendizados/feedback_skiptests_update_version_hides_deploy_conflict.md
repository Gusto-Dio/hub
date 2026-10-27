---
name: feedback_skiptests_update_version_hides_deploy_conflict
description: "Projeto com update_version em settings.json#skipTests não é pego pelo check_version.sh — a colisão de versão só aparece DEPOIS do merge, no deploy real pro Orchestrator"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 754b98fe-9dd7-425e-ba6e-ef0a96e69e4a
  modified: 2026-09-09T15:06:24.786Z
---

Quando um processo tem `"update_version"` em `settings.json#skipTests` (ex: `UHC_GroupSubmission_NewPlan_SAMx`), o `check_version.sh` do Buildkite não roda naquela PR — então uma PR pode mergear com `projectVersion` igual a uma versão que JÁ foi publicada em Produção por outro deploy anterior não relacionado, sem nenhum sinal de erro até o merge acontecer. O deploy pós-merge (que empacota e faz upload real pro Orchestrator) só falha DEPOIS, com `Package already exists` (`errorCode 1004`, Conflict) — ou seja, o PR já está mergeado em `develop` quando o problema aparece.

**Why:** aconteceu no BT-75454 (PR #3300) — `projectVersion` ficou em `1.56.8` (igual ao que já tinha sido publicado em Produção em 2026-08-28, de um deploy anterior sem relação com essa PR). Ninguém percebeu porque `check_version.sh` estava pulado pra esse processo. Confirmado com `uip or packages list --search <nome-do-pacote>` no tenant Production. Fix: PR de acompanhamento só com bump de `projectVersion` (1.56.8→1.56.9), sem tocar código.

**How to apply:** pra processos com `update_version` no `skipTests` (ver [[feedback_check_version_bump_before_pr]] pro caso normal com o check ativo), antes de abrir a PR checar manualmente a versão publicada real em Produção via `uip or packages list --search <package-name>` (trocar tenant com `uip login tenant set Production` e voltar depois) — não confiar só no que está em `develop`/local. Se o build falhar pós-merge com "Package already exists", é sempre isso: bumpar e abrir PR de correção rápida, sem precisar reverter nada.
