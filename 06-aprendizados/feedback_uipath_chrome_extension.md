---
name: feedback-uipath-chrome-extension
description: "UiPath Chrome extension install issue on VDI — fix: install as Current User, not All Users"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: e4e451d4-792e-4866-a618-1b16f77c5a04
---

Se a extensão UiPath no Chrome não instala corretamente (ou fica travada em versão antiga), desinstalar via Studio e reinstalar selecionando **Current User** resolve.

**Why:** No VDI (Windows Server), a instalação "All Users" (HKLM) não aplica corretamente a force-install no perfil do usuário atual. O perfil Chrome fica vazio e a extensão nunca aparece.

**How to apply:** Ao instalar a extensão pelo Studio → Home → Tools → Browser Extensions, sempre escolher "Current User" neste ambiente de VDI.
