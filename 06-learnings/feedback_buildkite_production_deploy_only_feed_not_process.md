---
name: feedback_buildkite_production_deploy_only_feed_not_process
description: "Buildkite autodeploy pra Production faz upload do pacote pro feed, mas NAO ativa/atualiza o Process — precisa promover a versao manualmente"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: d4a8b26a-3d0b-4cfb-b25d-ae75fb39e01b
  modified: 2026-09-15T23:09:22.912Z
---

O job `deploy.ps1` do Buildkite (pipeline `biztech-uipath-rpa`, branch `develop`) roda com `ORCHESTRATOR_FOLDER` unset nas credenciais (`\\fs3-prd-aws.gustocorp.com\BizTech\uipath-pipeline-creds.json`), então o `uipcli package deploy` sempre usa `--createProcess false`. O log mostra explicitamente: `"createProcess" option is set to "false", no process will be created in the Orchestrator`.

**Why:** confirmado no BT-75581 (PR #3334, build Buildkite #14569) — após o merge, o pacote `UHC_SAMX_NewHireEnrollment_Modern:1.3.10` apareceu no feed de Production (`uip or packages list --search`) com `IsActive: false`, mas o Process real na pasta `Benefits` (`uip or processes list --folder-path Benefits`) continuou em `1.3.9`, `IsLatestVersion: false`, até o usuário promover manualmente a versão no Orchestrator. Contradiz a expectativa de "autodeploy total" — [[feedback_buildkite_production_only_autodeploy]] cobre só a diferença Staging (manual) vs Production (auto), mas não cobre que mesmo em Production o autodeploy é só publish-to-feed, não bind-to-process.

**How to apply:** depois de qualquer merge em `develop` que afete um processo, NÃO assumir que já está rodando em Prod só porque o build do Buildkite passou. Sempre confirmar com `uip login tenant set Production` + `uip or processes list --folder-path Benefits --output-filter "[?contains(Name, '<ProcessName>')]"` — checar `ProcessVersion` e `IsLatestVersion: true`. Se ainda estiver na versão antiga, a ativação é manual (usuário faz via Orchestrator UI, ou `uip or processes update`). Só escrever "publicado/rodando em Prod" (PR, Jira, Slack) depois dessa confirmação.
