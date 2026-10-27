---
name: benops-rpa-setup
description: Use when a new BenOps RPA team member needs to set up their VDI — tools, Claude Code plugins, and MCP connections for the Gusto BizTech RPA team.
sdlc_phases: [operate]
allowed-tools: [Bash(winget *), Bash(npm *), Bash(pip *), Bash(git *), Bash(claude *), PowerShell, Read, Edit]
---

# BenOps RPA — Machine Setup

## Overview
Interactive setup checklist for new BenOps RPA team members. Checks what is already installed, then asks whether to proceed automatically or step-by-step for each item.

## Workflow

### Step 1 — Run the health check

Before anything else, check what is already installed:

```powershell
node --version
uip --version
python --version
pip show Pillow
Test-Path "C:\Windows\System32\python.cmd"
dotnet --version
pwsh --version
git --version
```

Present a summary table to the user:

| Tool | Expected | Status |
|---|---|---|
| Node.js | v18+ | ✅ / ❌ |
| UiPath CLI (uip) | 1.0.0+ | ✅ / ❌ |
| Python | 3.11.x | ✅ / ❌ |
| Pillow | installed | ✅ / ❌ |
| python.cmd wrapper | exists | ✅ / ❌ |
| .NET SDK | 8.0.x | ✅ / ❌ |
| PowerShell Core (pwsh) | 7.x | ✅ / ❌ |
| Git | 2.x | ✅ / ❌ |

Then ask:

> "Would you like me to install and configure everything automatically, or would you prefer to go step by step?"

---

### Step 2A — Automatic

If the user chooses automatic, run only the missing items, asking for confirmation before each group:

**Node.js** (install first — required by everything else):
```powershell
winget install OpenJS.NodeJS.LTS
```

**UiPath CLI:**
```powershell
npm install -g @uipath/cli
```

**Python 3.11:**
```powershell
winget install Python.Python.3.11
```

**Pillow:**
```powershell
pip install Pillow
```

**python.cmd wrapper** (replace USERNAME with the actual VDI username):
```powershell
$user = $env:USERNAME
$content = "@echo off`r`n`"C:\Users\$user\AppData\Local\Programs\Python\Python311\python.exe`" %*"
Set-Content -Path "C:\Windows\System32\python.cmd" -Value $content
```

**.NET SDK 8:**
```powershell
winget install Microsoft.DotNet.SDK.8
```

**PowerShell Core:**
```powershell
winget install Microsoft.PowerShell
```

**Git:**
```powershell
winget install Git.Git
```

**Git config** (ask for name and email first):
```powershell
git config --global user.name "First Last"
git config --global user.email "email@gusto.com"
git config --global core.editor "notepad"
```

**Claude Code — marketplaces and plugins:**
```powershell
claude plugins marketplace add github:UiPath/skills
claude plugins marketplace add github:obra/superpowers-marketplace
claude plugins marketplace add github:Gusto/sfdc-shared
claude plugins marketplace add github:Gusto/usp-shared

claude plugins install uipath@uipath-marketplace
claude plugins install superpowers@superpowers-marketplace
claude plugins install team-benops@sfdc-shared
claude plugins install eng-performance-reviews@usp-shared
claude plugins install permission-audit@usp-shared
```

> **Troubleshooting — plugin not found in catalog**
>
> If `claude plugins install` fails with "not found in catalog", use `--plugin-dir` pointing to the locally cached marketplace directory:
>
> ```powershell
> claude plugins install --plugin-dir "$env:USERPROFILE\.claude\plugins\marketplaces\usp-shared\plugins\eng-performance-reviews"
> ```
>
> The general pattern for any plugin from a marketplace is:
> ```
> ~\.claude\plugins\marketplaces\<marketplace-name>\plugins\<plugin-name>
> ```
> Run `ls "$env:USERPROFILE\.claude\plugins\marketplaces"` to see which marketplaces are available locally.

**settings.json — MCP permissions:**
Add the `permissions.allow` block to `~/.claude/settings.json`:

```json
"permissions": {
  "allow": [
    "mcp__claude_ai_Slack_Gusto_Offical__slack_search_public_and_private",
    "mcp__claude_ai_Slack_Gusto_Offical__slack_read_thread",
    "mcp__claude_ai_Slack_Gusto_Offical__slack_read_channel",
    "mcp__claude_ai_Slack_Gusto_Offical__slack_search_users",
    "mcp__claude_ai_Github-Gusto__pull_request_read",
    "mcp__claude_ai_Github-Gusto__search_pull_requests",
    "mcp__claude_ai_Github-Gusto__list_pull_requests",
    "mcp__claude_ai_Github-Gusto__list_branches",
    "mcp__claude_ai_Github-Gusto__get_me",
    "mcp__claude_ai_Jira_Confluence__searchJiraIssuesUsingJql",
    "mcp__claude_ai_Jira_Confluence__searchConfluenceUsingCql",
    "mcp__claude_ai_Jira_Confluence__getJiraIssue",
    "mcp__claude_ai_Jira_Confluence__getAccessibleAtlassianResources",
    "mcp__claude_ai_Jira_Confluence__lookupJiraAccountId",
    "mcp__claude_ai_Gsheets_Gusto__fetch"
  ]
}
```

---

### Step 2B — Step by step

If the user prefers manual, display each command block one at a time and wait for "done" before moving to the next.

---

### Step 3 — Manual steps (always required)

Regardless of automatic or manual, these items cannot be automated:

| Step | How |
|---|---|
| Connect MCPs via Runlayer | See Runlayer section in the Notion setup doc |
| Authenticate uip | Run `uip login` in terminal (opens browser) |
| Authenticate each MCP | Run `/mcp` in Claude Code → select connector → authenticate with Gusto account |
| Clone the repository | `git clone https://github.com/Gusto/biztech-uipath-rpa` (requires access from Thomas Taylor) |

---

### Step 4 — Final verification

Re-run the health check and show the updated status table. If everything is ✅, setup is complete.

## Reference
Full setup doc on Notion: https://www.notion.so/35dad673c6c281d09313e23bf1a2652d
