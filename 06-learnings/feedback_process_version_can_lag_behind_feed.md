---
name: feedback_process_version_can_lag_behind_feed
description: "Versão do Process em Prod pode estar bem atrás da versão mais nova no feed (autodeploy só publica); rebind traz tudo desde a versão ativa; checar `uip or processes list`, não só packages"
metadata:
  node_type: memory
  type: feedback
  originSessionId: a28d5d67-9e3c-42bc-8e5b-6f2ce8646c5b
  modified: 2026-10-28T22:59:29.692Z
---

No BT-77083 eu assumi que Prod estava na 6.0.7 (a versão do feed/PR), mas o Process `FloridaBlue_NewHireEnrollment` no folder Benefits estava na **6.0.5**; a 6.0.6 e a 6.0.7 estavam publicadas no feed e nunca ativadas. O rebind para 6.0.11 trouxe tudo de uma vez.

**Why:** o Buildkite autodeploy só publica o pacote no feed, não ativa o Process ([[feedback_buildkite_production_deploy_only_feed_not_process]]). Uma versão no feed não diz o que o robô executa.

**How to apply:** antes de dizer "Prod está na versão X" ou de descrever o delta de uma PR, rodar `uip or processes list --folder-path <folder> -n <nome>` (campo `ProcessVersion`) e comparar com `uip or packages list -s <nome>`. Ao rebindar, avisar o usuário do delta real (versões intermediárias nunca ativadas). Rebind em Prod = `uip login tenant set Production` → `uip or processes update-version <Key GUID> --package-version X --folder-path <folder>` → reler e conferir → voltar `uip login tenant set Staging` ([[feedback_uip_default_tenant_not_production]]). Exige aprovação explícita ([[feedback_staging_process_rebind_needs_explicit_approval]]).
