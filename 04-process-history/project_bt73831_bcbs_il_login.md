---
name: project_bt73831_bcbs_il_login
description: "BT-73831 — BCBS_IL_GroupSubmissions_MemberLevel_Modern 2.1.5: MERGEADO e em produção ✅ (2026-06-29) — CONCLUÍDO"
metadata: 
  node_type: memory
  type: project
  originSessionId: 518b3570-5bc9-4143-8236-e3c53b00ac25
---

BT-73831 — falha recorrente de produção no `BCBS_IL_GroupSubmissions_MemberLevel_Modern`.

## Status final (2026-06-29) ✅ CONCLUÍDO

PR #2862 mergeada (squash merge) em develop e deploy em produção confirmado pelo usuário.
Versão final: **2.1.5**

## Fixes aplicados

### Fix 1 — CloseAllApplications (v2.1.3)
`Framework/CloseAllApplications.xaml` era placeholder vazio — Chrome nunca era morto. No re-init, Chrome abria com página de erro, `LoginToBCBSTXIL` falhava com NodeNotFoundException.
**Fix:** KillProcess 'chrome' em TryCatch + logs Info.

### Fix 2 — EnterDependentInfo NClick_5 (v2.1.5)
`Activities/BCBS_TX_IL/Enrollment/Group/EnterDependentInfo.xaml` — `Click 'Continue'` (NClick_5) lançava NodeNotFoundException porque executava mesmo quando `pageLoaded=True` (página já havia avançado).
**Fix:** Guard com `Not pageLoaded` antes do NClick_5.

**Why:** Dois fixes independentes para falhas de re-init e de clique em página que já avançou.
**How to apply:** Ticket encerrado — não há pendências.
