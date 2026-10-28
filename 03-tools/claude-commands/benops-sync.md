---
name: benops-sync
description: Use to sync the BenOps RPA Hub Notion page with current GitHub PR statuses, Jira ticket statuses, and library versions. Call daily via /morning or standalone.
sdlc_phases: [operate]
requires_mcp: [jiraconfluencegusto, githubgusto, notiongusto]
allowed-tools: [mcp__claude_ai_Github-Gusto__list_pull_requests, mcp__claude_ai_Github-Gusto__pull_request_read, mcp__claude_ai_Github-Gusto__get_file_contents, mcp__claude_ai_Jira_Confluence__searchJiraIssuesUsingJql, mcp__claude_ai_Notion_Gusto__notion-query-data-sources, mcp__claude_ai_Notion_Gusto__notion-update-page, mcp__claude_ai_Notion_Gusto__notion-fetch, Bash(uip *)]
---

# /benops-sync — BenOps Notion Hub Sync

Sync the BenOps RPA Hub Notion page with current GitHub PR statuses, Jira ticket statuses, and library versions.

> **Language rule:** Every value written to Notion — field values, notes, PR strings, status labels, timestamps — must be in English. Never write Portuguese into any Notion field.

## Config
Update when roster, repo, or DB IDs change.

| Key | Value |
|---|---|
| Hub page ID | `35dad673c6c281ca9beed83cf58fdb22` |
| Processes DB ID | `ba7266d884b6425c9fc0036b483bd8d0` |
| Library DB data source ID | `27a0a131-61fe-4a8e-9101-3b83290c7718` |
| GitHub repo | `Gusto/biztech-uipath-rpa` |
| Orchestrator Libraries feed | `https://cloud.uipath.com/gustoinc/Production/orchestrator_/odata/Libraries?$top=100` |
| Jira project | `BT` |
| Team members (Jira usernames) | `currentUser(), "oscar.nunez", "ahsen", "harinath"` |

---

## Execution Plan

### STEP 1 — Fetch current state (run in parallel)

**1a.** Fetch all open PRs: `mcp__claude_ai_Github-Gusto__list_pull_requests`
- owner: `Gusto`, repo: `biztech-uipath-rpa`, state: `open`

**1b.** Fetch recently merged PRs (last 7 days): same tool, state: `closed`

**1c.** Fetch BenOps Jira tickets: `mcp__claude_ai_Jira_Confluence__searchJiraIssuesUsingJql`
- JQL: `project = BT AND assignee in (currentUser(), "oscar.nunez", "ahsen", "harinath") AND updated >= -30d ORDER BY updated DESC`
- Fields per ticket: `key`, `summary`, `status`, `issuetype`, `resolutiondate`, `created`, `assignee`

**1d.** Fetch Library DB rows: `mcp__claude_ai_Notion_Gusto__notion-query-data-sources`
- Data source: Config: Library DB data source ID
- Query: `SELECT * FROM "collection://27a0a131-61fe-4a8e-9101-3b83290c7718" WHERE "BenOps" = '__YES__'`
- Capture per row: `id`, `Library`, `GitHub Version`, `Orchestrator Version`, `Status`

---

### STEP 2 — Fetch Processes database rows

Use `mcp__claude_ai_Notion_Gusto__notion-query-data-sources` on Config: Processes DB ID.
Capture all rows with: page `id`, `Process`, `Status`, `PR Number`, `Jira Ticket`, `Last Synced`.

---

### STEP 3 — Build Processes update map

For each Processes row with a non-empty `Jira Ticket` field:
1. Find matching Jira ticket from Step 1c by ticket key → get Jira `status`
2. Find matching PR from Steps 1a/1b by searching for `[BT-XXXXX]` in PR title → get PR state and review status
3. Derive new Status using this exact mapping:

| Condition | Derived Status |
|---|---|
| Jira = Done AND PR merged | `"Deployed to Prod"` |
| Jira = Done AND PR open | `"Ready for Deployment"` |
| PR review state = CHANGES_REQUESTED | `"Pending Review"` |
| PR open AND has pending review requests | `"Pending Review"` |
| Jira = In Progress AND PR open | `"In Progress"` |
| Jira = In Progress AND no PR found | `"In Progress"` |
| No Jira match AND no PR match | skip — no update |

4. If derived status equals current Notion status → skip (no update needed)

---

### STEP 4 — Apply Processes updates

**All values written to Notion must be in English.**

For each row with a status change, use `mcp__claude_ai_Notion_Gusto__notion-update-page` to update:
- `Status` → derived status value (English label from mapping table above)
- `PR Number` → English format: `"#2683 Open — Changes Requested"` or `"#2683 Merged"`
- `date:Last Synced:start` → today's date (YYYY-MM-DD)

---

### STEP 5 — Sync Library DB

**All values written to Notion must be in English.**

**5a. Fetch Orchestrator latest versions**

```bash
uip orchestrator library list --output json
```

If `uip` does not support library listing, fetch via REST:
```
GET Config: Orchestrator Libraries feed
Authorization: Bearer <token>
```

> ⚠️ Do NOT use `uip package list` — it reads from the Processes feed and returns stale versions.
> Always use the Libraries feed (`odata/Libraries`) or the Orchestrator UI:
> `https://cloud.uipath.com/gustoinc/Production/orchestrator_/libraries/tenant?tid=11015&fid=46023`

Capture: `{ packageName → latestVersion }` mapping.

**5b. Fetch GitHub latest versions (run in parallel)**

For each Library DB row from Step 1d, read its `project.json`:
- Tool: `mcp__claude_ai_Github-Gusto__get_file_contents`
- owner: `Gusto`, repo: `biztech-uipath-rpa`
- path: `{Library}/project.json` (derive from `Library` field value)
- Extract `projectVersion` field
- If file not found → GitHub version = `""` (library not in repo)

**5c. Derive Library Status**

| Condition | Status |
|---|---|
| GitHub version = Orchestrator version | `"Up to Date"` |
| GitHub version > Orchestrator version (semver) | `"Behind"` |
| Orchestrator version > GitHub version (semver) | `"Orch Ahead"` |
| GitHub version exists, Orchestrator empty | `"Not Deployed"` |
| Orchestrator version exists, GitHub empty | `"Orchestrator Only"` |
| No change in either version | skip |

**5d. Update Library DB rows**

For each row where any value changed, use `mcp__claude_ai_Notion_Gusto__notion-update-page` to update:
- `GitHub Version` — semver string, e.g. `"1.550.8"`
- `Orchestrator Version` — semver string, e.g. `"1.550.8"`
- `Status` — English label from 5c table

Skip rows with no change.

---

### STEP 6 — Update hub timestamp

Use `mcp__claude_ai_Notion_Gusto__notion-update-page` on Config: Hub page ID.
Replace the existing timestamp line with (in English):
```
Synced daily via /benops-sync (GitHub PRs + Jira tickets) · Last synced: YYYY-MM-DD HH:MM
```

---

### STEP 7 — Report

Output in English:

```
### BenOps Sync complete
- X processes checked, Y statuses updated: [list process names + old → new status]
- Z libraries checked, W versions updated: [list library names + what changed]
- Timestamp updated on hub page
```

If no changes in either DB: output `No changes detected.`
