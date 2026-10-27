---
name: project_bbo3747_bsca_groupsubmissions_slo
description: "BBO-3747 Set SLO Rules for BSCA Processes — TICKET FECHADO ✅ (2026-08-11), PRs #3069/#3070 mergeadas pros dois BSCA GroupSubmission"
metadata: 
  node_type: memory
  type: project
  originSessionId: 4a9b7973-4df1-43b4-9622-72185ffef490
  modified: 2026-08-11T16:48:33.886Z
---

Ticket BBO-3747 (reporter: Sri) pedia SLO rules pros processos BSCA de Group Submission, com base no doc "Groups Submission SLO Intake — Questions & Options (slo-init)" (Google Doc linkado no ticket). Implementado via `slo.yaml` em cada processo (mesmo padrão já usado em `Advising_Beam_PacketCollection`, `Payroll/BED/IL_SUI` e `Kaiser_CA_MemberUpdates`), validado localmente com `.buildkite/slo_validate.sh`. Criticidade escolhida: **Important** (alerta Slack padrão `#benefits-rpa-error-channel`, sem PagerDuty/on-call).

- PR #3069 — `BSCA_GroupSubmissions_GroupLevel/slo.yaml` — ABERTA ✅ (2026-08-10), branch `BBO-3747-BSCA-GroupLevel-slo-rules`
- PR #3070 — `BSCA_GroupSubmissions_MemberLevel/slo.yaml` — ABERTA ✅ (2026-08-10), branch `BBO-3747-BSCA-MemberLevel-slo-rules`
- Comentário postado no Jira com approach e links das PRs.

**Achado importante:** a taxa de falha bruta de job em Produção (33.6% GroupLevel / 58.1% MemberLevel, últimos ~4 meses via `uip orchestrator jobs list`) NÃO foi usada como base dos thresholds de `error_rate`/`error_count` — está contaminada por um bug de seletor recorrente (`navbar "Small*Business"` não encontrado no Init, presente há meses) que afeta os dois bots, e no MemberLevel também por uma dependência `ConnectionClient` faltando (quebra `Gusto_Benefits.AWS.GetS3Census`). Ambos os bugs já são conhecidos pela equipe/Sri — fora do escopo do BBO-3747, não abri ticket separado. Usei os defaults do catálogo (`slo-rules/catalog.yaml`: error_rate 5%/3%, error_count 50/20) em vez da taxa observada.

`execution_time` foi calculado com base no p95 real observado + buffer sobre o max histórico (3600s GroupLevel, 7200s MemberLevel — este roda bem mais tempo). `throughput` critical=1 pro piso mínimo (ambos baixo volume diário). Sem `burn_rate` (só mission-critical tem).

**Why:** usuário foi explícito em não querer números de threshold "que possam trazer questionamentos" — por isso a investigação de causa raiz via amostragem de jobs Faulted antes de definir os valores, em vez de só copiar a taxa bruta observada.

**How to apply:** depois do merge dos PRs em `develop`, confirmar no Datadog que o `slo_sync.sh` criou os monitores esperados (tags `rpa-bot:<path>`). Sem bump de versão/redeploy necessário — `slo.yaml` é excluído do pipeline de deploy (`.buildkite/pipeline.sh`), só alimenta os steps separados de SLO Validate/Sync.

**CONCLUÍDO (2026-08-11):** ticket fechado — PRs #3069 e #3070 mergeadas em `develop` pros dois processos (GroupLevel e MemberLevel). Confirmar no Datadog os monitores criados fica pra próxima vez que alguém tocar nesses SLOs, não é bloqueador.

**Follow-up 2026-08-11 (mesmo dia):** Sri pediu no Slack (`#usp-rpa-benops-support-dev`) que o time atualize a coluna E ("SLO Rule Status") da planilha de tracking conforme completar os `slo.yaml` — ver [[reference_benops_bots_tracking_sheet]]. Atualizado pra "Deployed to Prod" nas linhas 52 (`BSCA_GroupSubmissions_GroupLevel`) e 53 (`BSCA_GroupSubmissions_MemberLevel`). Confirmado na thread do pedido. Também mandei update assíncrono de status pro Sri (BBO-3747 done + BT-74849 em andamento) na thread principal de scrum/support.
