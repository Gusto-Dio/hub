---
name: benops-ticket-investigation
description: Use when a BenOps RPA process is failing in Production and a bug ticket needs investigation — before reading any XAML code or proposing a fix
sdlc_phases: [operate]
requires_mcp: [jiraconfluencegusto, githubgusto, gsheetsgusto]
allowed-tools: [Bash(uip *), PowerShell, Read, Grep, Glob, mcp__claude_ai_Jira_Confluence__getJiraIssue, mcp__claude_ai_Jira_Confluence__searchJiraIssuesUsingJql, mcp__claude_ai_Github-Gusto__list_pull_requests, mcp__claude_ai_Github-Gusto__get_file_contents, mcp__claude_ai_Github-Gusto__list_commits, mcp__claude_ai_Gsheets_Gusto__fetch, mcp__claude_ai_Gsheets_Gusto__update]
---

# BenOps Ticket Investigation

## Output Language
**Always respond in English**, regardless of the language used in the conversation.

## Overview
Structured investigation workflow for BenOps RPA production failures. Core principle: **Orchestrator logs are ground truth — code analysis without logs first produces wrong root causes.**

## The Iron Rule
**Pull Orchestrator production logs BEFORE reading any process code.**

See `references/investigation-rules.md` for the full red flags and common mistakes list.

## Config
| Key | Value |
|---|---|
| Sheets ID | `1jb2atbGZXusvwDCh9a8DocVnhe4QaU_Hcm2rl2Ue0T0` |
| Sheet tab | `RPA BenOps Nov 2025` |
| Ticket ID column | A |
| Status column | K |
| Dev Start Date column | discover from header row (column named `Dev Start Date`) |

---

## Investigation Order (Non-Negotiable)

### Phase 0 — Google Sheets Update (non-blocking)

Run this first. If it fails or the ticket is not found, **do not stop** — continue to Phase 1 and report the issue at the end.

1. Fetch the sheet tab from Config using `mcp__claude_ai_Gsheets_Gusto__fetch`.
2. In row 1 (header), find the column named **`Dev Start Date`** — note its letter.
3. Search column A for a cell matching the ticket ID argument (e.g., `BT-72268`).
4. **If found:**
   - Update Status column (K) for that row → `"In Progress"`
   - Update the `Dev Start Date` column for that row → today's date (`YYYY-MM-DD`)
5. **If not found:** note it as `_sheets_not_found = true` — continue investigation, report at the end.

### Phase 1 — Orchestrator Production Logs
Pull logs using the Orchestrator REST API. Full query guide, auth instructions, error pattern reference, and tenant IDs: `references/orchestrator-log-queries.md`

**Extract verbatim error messages first.** These drive everything else. Do NOT ask the user to provide logs.

### Phase 2 — Jira Ticket
Pull the ticket via Jira MCP:
- Confirm the exact failure mode described matches the logs
- Check linked tickets — related issues often cover the same process
- Note when failures started — correlates with recent deploys

### Phase 3 — Git History for the Process
```powershell
git log --oneline -- "Processes/.../ProcessName/" | head -20
```
Cross-reference commit dates with when failures started.

### Phase 4 — Recent PRs
Check GitHub PRs merged to `develop` in the last 30–60 days touching the process folder. Dependency bumps and selector changes are the most common regression source.

### Phase 5 — Targeted Code Analysis
**Read ONLY what the logs point to.** The error message and stack trace tell you exactly which file and activity to inspect — do not read the whole process.

### Phase 6 — Fix Proposal
Structure every proposal as:

```markdown
## Root Cause
[Verbatim error from Orchestrator logs]
[File and line where the issue originates]

## Fix
[Specific change — file, activity, selector, or missing file to create]

## Risk
[What breaks if fix is wrong; what other workflows touch this code]

## Test Plan
- [ ] Minimum 3 transactions in Staging Orchestrator
- [ ] Transaction IDs documented
- [ ] No Library files modified (process-level fix only)
```

If `_sheets_not_found = true`, append this note after the proposal:

> ⚠️ **Sheets:** Ticket [ID] was not found in the tracking spreadsheet. Status and Dev Start Date were not updated — please update manually.
