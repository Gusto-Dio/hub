---
name: project_bt73389_floridablue_terminations
description: "BT-73389 — FloridaBlue_Terminations screenshot bug — PR #2872 ABERTA ✅ (2026-06-29)"
metadata: 
  node_type: memory
  type: project
  originSessionId: 73d91e88-c0a9-407a-b51f-40b52e563594
---

BT-73389 — `FloridaBlue_Terminations` falha recorrente: screenshot de confirmação mostrava popup de sucesso do portal em vez da página do EE com data de terminação.

## Status (2026-06-29) — PR #2872 ABERTA ✅

### Branch
`BT-73389-FloridaBlue-Terminations-confirmation-screenshot-fix`

### PR
https://github.com/Gusto/biztech-uipath-rpa/pull/2872

### Root cause
Após `Click 'Submit'` em `TerminateEmployee.xaml`, o portal exibe popup de sucesso. O `Click 'X'` (legacy `ui:Click` com `SimulateClick="True"`) não fecha o popup de forma confiável pós-migração para Windows. O popup persiste quando `TakeFullPageScreenshot` roda em `ProcessTransaction.xaml`.

### Versão final: 6.1.1

### Commits
- `5753a2fe8` — Fix 1 (NCheckState) + Fix 2 (UiElementExists guard) — v6.1.0
- `6b70d4c60` — Polish: display name, log typo, timeout 20→10 — v6.1.1

### Fixes aplicados — v6.1.1

**Fix 1 — TerminateEmployee.xaml ✅**
`uix:NCheckState` (timeout 10s) após `Click 'Submit'` detecta "Unable to Submit: Pending transaction already exists for this change" → loga + lança `BusinessRuleException`.

**Fix 2 — TerminateEmployee.xaml ✅**
`Click 'X'` guardado por `UiElementExists` (TimeoutMS=8000, WaitForReady=COMPLETE) em variável `boolX`. Se popup presente → Click 'X' com DelayBefore=5000 + LogMessage Info; se ausente → segue sem erro.

**Polish — TerminateEmployee.xaml ✅**
- DisplayName: "Element Exists" → "Element Exists 'Success Popup Button'"
- Log message: "Clicked on X bottom to close poup-up" → "Clicked on X button to close popup"
- NCheckState timeout: 20s → 10s

### Staging — situação final (2026-06-29)
- Pacote 6.1.1 publicado no Staging ✅
- Processo atualizado para 6.1.1 (key: `46607e98-b145-4291-8c2b-d9d145c4c350`) ✅
- Teste com sucesso: Item 2404858053 (Bryan Blanco, K6208) — screenshot capturou página do EE ✅

### Infraestrutura
- Python: `C:\Python314\python.exe` (Python 3.11 não existe mais na VDI)
- Pillow 12.2.0 instalado ✅
- Robot machine não tem Python — debug rodado localmente via Studio
- `project.json` requer campo `description` não-vazio para `uip rpa pack` funcionar

**Why:** Falha recorrente em produção — screenshots errados impossibilitam validação manual.
**How to apply:** PR aberta, aguardando review/merge.
