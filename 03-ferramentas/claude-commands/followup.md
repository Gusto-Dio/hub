---
name: followup
description: Send daily status update to Sri/Oscar via Slack. Reads Sheets queue, open PRs, and Jira tickets to compose a concise English update.
sdlc_phases: [operate]
requires_mcp: [jiraconfluencegusto, githubgusto, slackgustoofficialmcp, gsheetsgusto]
allowed-tools: [mcp__claude_ai_Gsheets_Gusto__fetch, mcp__claude_ai_Github-Gusto__list_pull_requests, mcp__claude_ai_Github-Gusto__pull_request_read, mcp__claude_ai_Jira_Confluence__searchJiraIssuesUsingJql, mcp__claude_ai_Slack_Gusto_Offical__slack_send_message, AskUserQuestion]
---

# /followup — Status Update

Send a concise daily status update via Slack. The user chooses the destination before sending.
Respond in English. All Slack messages must be in English.

## Config
Update these values when deploying for a different user.

| Key | Value |
|---|---|
| My name | `Diogenes` |
| My Slack ID | `U0ARX71R5FS` |
| Sri Perinkolam Slack ID | `U07KMNHHFB6` |
| Oscar Nuñez Slack ID | `U05UYA9S4G7` |
| Group DM (me + Sri + Oscar) | `C0AV2UULSER` |
| BizTech RPA channel | `C0AFP67B5AQ` |
| GitHub login | `Gusto-Dio` |
| Jira Cloud ID | `3fd33630-4e39-4689-ad04-db32e3843117` |
| Sheets ID | `1jb2atbGZXusvwDCh9a8DocVnhe4QaU_Hcm2rl2Ue0T0` |
| Sheet tab | `RPA BenOps Nov 2025` |
| Sheets name filter | `Diogenes` |

---

## Execution Plan

### STEP 1 — Gather context (run in parallel)

**A) Google Sheets — work queue**
Fetch the sheet tab (Config: Sheet tab) from the Sheets ID in Config.
Filter rows where column E (Resource responsible) contains Config: Sheets name filter (case-insensitive).
From those rows, extract:
- Column A: Ticket ID
- Column C: Priority
- Column K: Status
- Column P: Current Jira tkt (if filled)

Classify each ticket:
- **Current** — Status contains "In Progress" or "In Dev" or similar active state
- **Next** — Status is empty, "To Do", "Ready", "Backlog", or "Not Started"
- **Done** — Status is "Done" or "Completed" → EXCLUDE from the update

**B) GitHub — open PRs**
Call list_pull_requests: owner=Gusto, repo=biztech-uipath-rpa, state=open, sort=updated, direction=desc, perPage=50.
Filter to PRs where author.login matches Config: GitHub login. Take the 3 most recent.
For each, get:
- PR number and title
- Review status: approved / changes requested / awaiting re-review / awaiting review
- CI status: passing / failing / pending

To determine review status:
- Latest review = "changes_requested" AND most recent commit is by the author → "awaiting re-review"
- Latest review = "changes_requested" AND no author response → "changes requested"
- Latest review = "approved" → "approved"
- No reviews yet → "awaiting review"

**C) Jira — active tickets**
Query: `assignee = currentUser() AND status in ("In Progress", "In Review") ORDER BY updated DESC`
Fields: summary, status, priority, updated

---

### STEP 2 — Determine current state

- If there is a **current ticket** in Sheets → actively working on it
- If all Sheets tickets are **Done** or no active ticket → may be ready for next
- List **next tickets** (up to 3) ordered by Priority (High first)

---

### STEP 3 — Compose the status message

```
Hi Sri,

Here's my status for today (DATE):

*Currently working on:*
• [Ticket ID] — [short description] — [Jira link if available]
[If nothing active: "Finished current work and ready to pick up the next ticket."]

*PRs in flight:*
• #XXXX [PR title] — [review status] — [CI status]
[If none: omit this section]

*Up next (queue):*
• [Ticket ID] — [short description] — Priority: [High/Medium/Low]
[list up to 3, or omit if queue is empty]

*Blockers:*
[PRs with "changes requested" where author has NOT yet responded. If none: omit.]

— [Config: My name]
```

---

### STEP 4 — Present draft and ask destination

Show the draft, then ask:

"Here's the draft — where do you want to send it?

**1.** DM to Sri only
**2.** Group (me, Sri, and Oscar)
**3.** Channel #biztech-rpa"

Accept numeric answers (1, 2, 3) or natural language.

---

### STEP 5 — Send via Slack

| Option | Destination | channel_id |
|---|---|---|
| 1 | DM to Sri | Config: Sri Perinkolam Slack ID |
| 2 | Group DM | Config: Group DM |
| 3 | Channel | Config: BizTech RPA channel |

After sending, confirm:
- Option 1: "Sent to Sri ✓"
- Option 2: "Sent to group (Sri + Oscar) ✓"
- Option 3: "Sent to channel ✓"
