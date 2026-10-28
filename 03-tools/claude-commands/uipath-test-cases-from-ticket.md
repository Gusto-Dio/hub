---
name: uipath-test-cases-from-ticket
description: Create UiPath Staging test cases from a JIRA ticket. Reads the ticket, samples production queue items, and launches the recreator job in Staging.
argument-hint: <ticket-id> [--count N] [--clean-staging] [--include-failed] [--monitor]
sdlc_phases: [test]
requires_mcp: [jiraconfluencegusto]
allowed-tools: [Bash(uip *), mcp__claude_ai_Jira_Confluence__getJiraIssue, AskUserQuestion]
---

The user wants to create UiPath Staging test cases tied to a JIRA ticket.

Arguments passed by the user: `$ARGUMENTS`

Use the `uipath-test-cases-from-ticket` skill to handle this end-to-end. The skill's workflow:

1. Reads the JIRA ticket via the JIRA MCP.
2. Resolves the worker project, Orchestrator folder, and queue name.
3. Counts Production queue items and asks the user how many test cases to create.
4. Samples a varied subset (recent + middle + oldest).
5. Optionally cleans the Staging queue first.
6. Launches the `QueueItemRecreator` job in Staging.

If `$ARGUMENTS` is empty, ask the user for the ticket ID before proceeding. Otherwise, treat the first token as the ticket key and the rest as flags.
