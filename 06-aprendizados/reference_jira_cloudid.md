---
name: reference_jira_cloudid
description: "cloudId correto pra chamadas mcp__jiraconfluencegusto — gustohq.atlassian.net, não gusto.atlassian.net"
metadata: 
  node_type: memory
  type: reference
  originSessionId: ce468a28-b643-41c1-90f2-fe4e1d4e55e6
  modified: 2026-08-11T20:49:17.540Z
---

O cloudId certo pras tools `mcp__jiraconfluencegusto__*` (ex: `getJiraIssue`) é **`gustohq.atlassian.net`**.

`gusto.atlassian.net` (a suposição óbvia pelo nome da empresa) dá erro 404 ("Failed to fetch tenant info").

**How to apply:** ao chamar qualquer tool `mcp__jiraconfluencegusto__*` que peça `cloudId`, usar `gustohq.atlassian.net` direto. Se algum dia der 404 de novo, rodar `getAccessibleAtlassianResources` (sem parâmetros) para confirmar o cloudId atual antes de insistir.
