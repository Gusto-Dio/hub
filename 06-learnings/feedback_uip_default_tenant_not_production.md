---
name: feedback_uip_default_tenant_not_production
description: "uip CLI session tenant is not reliably Production by default — always check `uip login status` before pulling logs"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 93fdb1e7-15ee-40f8-9a27-a06e7b9e7d1c
---

Sempre rodar `uip login status` antes de puxar logs/queue items do Orchestrator para uma investigação — não confiar que a sessão `uip` está em Production só porque o CLAUDE.md diz que é o default.

**Why:** Durante a investigação da BT-74133 (2026-07-09), a sessão `uip` estava conectada ao tenant **Staging** (confirmado via `uip login status` → `"Tenant": "Staging"`), apesar do CLAUDE.md afirmar que a conexão `uip` padrão bate em Production. Só foi descoberto porque o `OrganizationUnitId` retornado pelas queries (48382) batia com o ID de Staging/Benefits documentado, não Production/Benefits (46023). Sem esse cross-check, a investigação teria analisado dados errados.

**How to apply:**
1. Antes de qualquer Phase 1 (Orchestrator logs) de investigação: `uip login status` → confirmar `"Tenant": "Production"`.
2. Se estiver em Staging: `uip login tenant set Production`.
3. Ao terminar a investigação (read-only), trocar de volta pro tenant em que a sessão estava originalmente (`uip login tenant set Staging`), para não deixar a sessão do usuário em um estado inesperado.
4. Folder IDs de referência: Production/Benefits=46023, Staging/Benefits=48382, Production/CarrierAutomation=944168, Staging/CarrierAutomation=946022 — útil para confirmar cross-tenant se `OrganizationUnitId` aparecer nos dados retornados.

Related: [[uip_rpa_cli_reference]], [[project_bt74133_bcbs_ma_add_dependent]].
