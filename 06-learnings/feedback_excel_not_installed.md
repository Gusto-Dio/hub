---
name: excel-not-installed
description: Excel foi instalado na VDI em 2026-07-01 (antes não estava disponível)
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 119f3cd5-eaa0-402a-9b5c-8e6ac8ebd110
---

Excel agora está instalado na máquina/VDI do Dio (confirmado por ele em 2026-07-01).

**Why:** Historicamente Excel não estava presente (winget install via Microsoft.Office falhou com exit code 17006 — bloqueio de política corporativa/Intune). O usuário conseguiu instalar por conta própria depois disso.

**How to apply:** Não assumir mais que Excel está ausente — pode sugerir .xlsx/.xls normalmente. Se voltar a falhar, reverter para alternativas: Google Sheets, CSV, PowerShell, Python, ou Watch/Locals panel no Studio.
