---
name: feedback_gh_cli_not_installed
description: gh CLI não está instalado na VDI — usar GitHub MCP (mcp__githubgusto__create_pull_request) para criar PRs
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 73d91e88-c0a9-407a-b51f-40b52e563594
---

`gh` (GitHub CLI) não está instalado na VDI do dev. Qualquer tentativa de `gh pr create` falha com "command not found".

**Why:** A VDI não tem `gh` no PATH, e instalar requer permissão de admin.

**How to apply:** Para criar PRs, usar o MCP tool `mcp__githubgusto__create_pull_request` diretamente (owner: `Gusto`, repo: `biztech-uipath-rpa`). Carregar o schema com `ToolSearch` se necessário: `select:mcp__githubgusto__create_pull_request`.
