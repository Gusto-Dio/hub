---
name: feedback-read-clipboard-when-paste-fails
description: "Colar texto/link no terminal da VM falha pro Dio; quando ele disser \"clipboard\"/\"tá no clipboard\", ler com Get-Clipboard sem pedir de novo"
metadata:
  node_type: memory
  type: feedback
  originSessionId: 5e203aa4-1bd1-4ff8-ad47-6036ad823343
  modified: 2026-10-29T03:16:24.147Z
---

Na VM, o Dio não consegue colar no prompt do Claude. Quando ele disser que algo "está no clipboard" (link do Jira/Google Doc, ticket BBO/BT, texto), rodar `Get-Clipboard -Raw` (PowerShell) imediatamente, sem pedir pra ele colar nem confirmar.

**Why:** ele já pediu duas vezes e não quer repetir toda hora.
**How to apply:** se o conteúdo for um link, abrir pela ferramenta certa (Jira `getJiraIssue` com cloudId gustohq.atlassian.net; Google Doc `fetch_all_tabs` com `document_id`; Notion `notion-fetch`). Docs grandes caem em arquivo: ler com python -I + json. Relacionado: [[reference_jira_cloudid]].
