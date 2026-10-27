---
name: feedback-gsheets-sheet-name-leading-space
description: "A aba 'RPA BenOps Nov 2025' da planilha de tracking tem um espaço à esquerda no nome real"
metadata:
  node_type: memory
  type: feedback
  originSessionId: 9ab9732d-9995-4710-8615-d44f15dd4f73
---

O nome real da aba da planilha de tracking BenOps (ID `1jb2atbGZXusvwDCh9a8DocVnhe4QaU_Hcm2rl2Ue0T0`) é **`" RPA BenOps Nov 2025"` com um espaço à esquerda**, não `"RPA BenOps Nov 2025"` como aparece nas instruções do skill `/benops-ticket-investigation`.

**Why:** `mcp__claude_ai_Gsheets_Gusto__fetch` com `sheet_name` ou `range` usando o nome sem o espaço falha com `"Unable to parse range"`. Só funciona omitindo `sheet_name`/`range` (pega a primeira aba, que é essa mesma) ou usando o nome exato com o espaço.

**How to apply:** ao buscar essa planilha, chamar `fetch` sem `range`/`sheet_name` (retorna a primeira aba direto) em vez de tentar especificar o nome da aba. Colunas confirmadas: Ticket ID=A, Stream=B, Priority=C, Category/UiPath Folder=D, Resource responsible=E, Tkt Created Date=F, USP Teams Attended Date=G, **Dev Start Date=H**, Target Closure Date=I, Actual Tkt Closed Date=J, **Status=K**, Updates=L, Comments=M, Solution=N, Resources Identified=O, Current Jira tkt=P, BIZ INPUTs=Q. Dados terminam em ~BT-72959 (maio/2026) na sessão de 2026-07-09 — tickets mais recentes (BT-74xxx) não estão na planilha ainda.
