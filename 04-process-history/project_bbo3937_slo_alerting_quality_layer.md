---
name: project_bbo3937_slo_alerting_quality_layer
description: BBO-3937 Quality Layer SLO Finetuning — Feature 1 (SLO Rules and Slack Routing) é a próxima a implementar; branch piloto existe, não mergeada, precisa de merge do develop
metadata:
  type: project
  originSessionId: 5e203aa4-1bd1-4ff8-ad47-6036ad823343
  modified: 2026-10-29T03:22:45.056Z
---

BBO-3937 (Story, P2, In Progress, reporter Sri, epic BBO-3735 "Quality SLO Layer for the RPA Bots"). Doc mestre no Notion: "Quality Layer SLO Finetuning" (https://app.notion.com/p/3f4ad673c6c281a897adf0c85fade1ec), com 3 sub-páginas. Revisado por Oscar (aprovou o design em 14/10) e Thomas (reunião 22/10, definiu a Feature 1 como a primeira a construir).

**Decisão da reunião com Thomas (22/10):** só a Feature 1 agora (SLO rules + alertas no Slack do canal do dono). Alert to Ticket Flow (Feature 2) e Triage (Feature 3) ficam em backlog, sem escopo. A skill "Ask & Collect" da v1 foi abandonada: na v2 o ticket é o registro e o dono do processo confirma a mudança de regra no PR (Jack = packet collection, Tami = member ops, Bree = group ops).

**Feature 1, stories em ordem:**
1. Fine-tune dos `slo.yaml` dos 3 bots piloto (Anthem_Packets, BCBS_IL_Packets, BCBS_MA_Packets) incluindo `throughput`, com estimativa de alertas/mês antes de mergear (condição do Oscar: limpar ruído primeiro; hoje 32 alertas/30 dias, 20 de throughput).
2. `owner_group` nos 3 arquivos (só vale quando o sync script ler o campo).
3. Checar logging do tipo de exceção (Anthem e BCBS_IL já logam; BCBS_MA falta checar), depois adicionar as regras de contagem system/business.
4. Catálogo de erros de negócio (dono confirma cada entrada no PR).
5. Rotear alertas pro canal do `owner_group` (precisa nomes de canal confirmados em `slo-rules/owner-map.yaml`).
6. Corrigir `throughput` (alertar com trabalho na fila não processado; precisa de queue depth, proposta: poll da API do Orchestrator; tira ~69% dos alertas).
7. Apagar/consertar 91 monitores mortos. 8. Restante da frota.

**Estado do código:** branch `origin/bbo-3937-slo-packet-collection-pilot` (commits de 24-30/09: fine-tune das 3 métricas com baseline de 91 dias, regra `business_error_count` no catalog, `owner_group` só no Anthem, `owner-map.yaml`). Sem PR. NÃO tem `throughput` nem estimativa de alertas/mês. Está defasada do develop (develop ganhou validação de janela 48h #3444/#3445 e SLOs ADM #3157/#3158; diff do catalog.yaml mostra -197 linhas por defasagem). Commits de 30/09 (business_error_count) vieram antes da story 3, reavaliar.

**Why:** Sri quer alertas na hora certa com aprovação certa antes de criar ticket; Thomas priorizou Slack antes de ticket.
**How to apply:** próxima sessão (30/10 cedo, Dio pediu): criar/atualizar branch off `origin/develop` (nunca develop), validar com `.buildkite/slo_validate.sh`, começar pela story 1. Medir `throughput`/alertas por mês exige leitura em Production: pedir aprovação explícita (`uip login status` primeiro, voltar pra Staging). slo.yaml não passa por deploy/projectVersion (ver [[project_bbo3747_bsca_groupsubmissions_slo]]). Pontos em aberto: nomes de canal no owner-map (time confirma), aprovação de regra vs "right approvals" do ticket (Dio confirma com Sri), PSVULN-6030 (bots reportam exceção como Successful), PSVULN-2063 (CI validar owner_group). Ata da reunião: Google Doc "Diógenes / Thomas - 2026/10/22" (Gemini notes). Também no ata: Dio deve dividir o doc em features (feito, página v2 de 26/10), fazer walk-through com Thomas e postar a atualização no canal dev.
