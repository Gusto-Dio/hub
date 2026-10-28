---
name: reference_benops_bots_tracking_sheet
description: "Planilha \"Current BenOps Bots Inventory\" — onde registrar status de SLO rules e migração por processo"
metadata: 
  node_type: memory
  type: reference
  originSessionId: 46def792-e01f-4b8b-8cb4-1d79a9767bdf
  modified: 2026-08-11T16:48:23.818Z
---

Planilha "RPA BenOps Bots Inventory" (Google Sheets, id `1Fx5Yt8Up3JhpPFhbokRXbQgr7UiTA38dGClY3Oxzoi8`), aba "Current BenOps Bots". Uma linha por processo, colunas: A=Process Name, B=Legacy/Modern, C=Category (GOPS/MOPS/Reconcillation/Packet Collection/Advising Packet Collection), D=Migration Status, E=SLO Rule Status, F=Studio Version, G=Status (ex: "Running Fine", "Faulting Frequently", "Deprecated"), H=Automation Done By, I=Total Volume.

Sri pediu (2026-08-11, thread `#usp-rpa-benops-support-dev`) que o time atualize a coluna E ("SLO Rule Status") conforme for completando os `slo.yaml` de cada bot. Valor usado quando o SLO já foi implementado e mergeado: **"Deployed to Prod"** (mesma convenção da coluna D, confirmado com o usuário) — antes disso a maioria das linhas está em "Not Started".

**Why:** rastreamento centralizado do rollout de SLO rules (iniciativa BBO-3747 e relacionadas) pro time inteiro, não só BenOps RPA.

**How to apply:** sempre que um PR de `slo.yaml` for mergeado pra um processo, atualizar a linha correspondente na coluna E pra "Deployed to Prod" e confirmar na thread do Sri. Ver [[project_bbo3747_bsca_groupsubmissions_slo]] pro primeiro caso (BSCA GroupLevel/MemberLevel, linhas 52-53).
