---
name: morning
description: Daily briefing — reads Slack, Jira, and GitHub in parallel. Covers priority contacts, alerts, active tickets, open PRs, and next ticket suggestion.
sdlc_phases: [operate]
requires_mcp: [jiraconfluencegusto, githubgusto, slackgustoofficialmcp]
allowed-tools: [mcp__claude_ai_Slack_Gusto_Offical__slack_search_public_and_private, mcp__claude_ai_Slack_Gusto_Offical__slack_read_channel, mcp__claude_ai_Slack_Gusto_Offical__slack_read_thread, mcp__claude_ai_Jira_Confluence__searchJiraIssuesUsingJql, mcp__claude_ai_Jira_Confluence__getJiraIssue, mcp__claude_ai_Github-Gusto__list_pull_requests, mcp__claude_ai_Github-Gusto__pull_request_read, Skill, Agent]
---

# /morning — Daily Briefing

Run a structured daily briefing by reading Slack, Jira, and GitHub in parallel.
Respond in English. All tool calls and external content remain in English.

## Config
Update these values when deploying for a different user.

| Key | Value |
|---|---|
| My name | `Diogenes` |
| My Slack handle | `@diogenes` |
| My Jira username | `diogenes.ribeiro` |
| Priority contacts | Jonathan Boice, Oscar Nunez, Sri |
| Jira Cloud ID | `3fd33630-4e39-4689-ad04-db32e3843117` |
| GitHub login | `Gusto-Dio` |

---

## Execution Plan

Run the following steps using parallel sub-agents where possible.

---

### STEP 1 — Priority Contacts Sweep (highest priority, run first)

Search Slack and other tools for any activity from the people listed under Config: Priority contacts.

For each person, check:
1. Did they send me a direct message in the last 24h?
2. Did they mention me (Config: My Slack handle) in any channel in the last 24h?
3. Did they comment on any of my GitHub PRs?
4. Did they assign a Jira ticket to me or mention me in a ticket comment?
5. Did they share a document, Confluence page, or Sheets link that requires my review or validation?

For each finding, capture: who sent it, what it is, where (channel/tool), and what action it likely requires from me.

---

### STEP 2 — Slack Overview (last 16 hours)

Search the following Slack channels for relevant activity:
- Any channel related to BizTech, RPA, automation, or carrier integrations
- Any channel where I was mentioned (Config: My Slack handle) or DMs sent to me
- Look for: incident alerts, urgent bugs, deployment failures, process failures, PR review requests

Capture: channel name, sender, summary of message, required action if any.

---

### STEP 3 — Jira Board

Query Jira for:
1. My tickets with status `In Progress` or `In Review`
2. Tickets assigned to me with status `To Do` or `Ready` (sorted by priority)
3. Tickets where I was mentioned in a comment in the last 24h
4. Any ticket updated or commented on by Config: Priority contacts

For each ticket: ID, title, status, last update, and what the next action is.

---

### STEP 4 — GitHub PRs

Check the `Gusto/biztech-uipath-rpa` repository for:
1. My open PRs — check CI status (Buildkite), review requests, and pending comments
2. PRs where I was requested as reviewer
3. Any PR comments or reviews from Config: Priority contacts in the last 24h

---

### STEP 5 — Synthesize and Present

Present the briefing in this exact structure:

```
## Good morning, [Config: My name]

### Immediate action (priority contacts)
[List findings from Step 1 — any message/ticket/PR from Config: Priority contacts]
[If none: "Nothing from [priority contacts] in the last 24h."]

### Urgent alerts
[Incidents, broken bots, urgent Slack messages, CI failures]
[If none: "No urgent issues identified."]

### Active tickets
[In Progress tickets with current status and next action]

### PRs awaiting action
[Open PRs with CI status and pending reviews]

### Next suggested ticket
[Top priority To Do ticket with brief reason why]

### Day summary
[2-3 sentences: what to focus on today, in what order, and why]
```

Keep each section tight — one line per item where possible. If a section is empty, say so in one line rather than omitting it.

Do not include raw message dumps or full ticket descriptions. Summarize to the minimum needed for me to decide what to do next.

Always end the briefing with this fixed block, exactly as written:

```
### Tools
/morning · /benops-ticket-investigation BT-XXXXX · /analyze · /followup · /benops-sync
```

If the **Urgent alerts** section contains any broken bot, Orchestrator failure, or unexplained error, add this line immediately after that section (not in the fixed block):

> "To diagnose: use `superpowers:systematic-debugging` — structured root cause protocol."

---

### STEP 6 — Sync BenOps Notion Hub

After presenting the briefing, run `/benops-sync` to update the Processes database.
This step runs silently — if sync completes with no changes, append only one line to the briefing:
> "🔄 BenOps Hub synced."
If there were status changes, append the full sync summary block from `/benops-sync` output.
