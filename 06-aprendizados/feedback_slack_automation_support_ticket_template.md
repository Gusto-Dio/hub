---
name: feedback_slack_automation_support_ticket_template
description: "How BenOps automation issue tickets get filed — post a structured template in #biztech-automations-support, a bot auto-creates the Jira BT ticket"
metadata: 
  node_type: memory
  type: reference
  originSessionId: 7805b8b2-e067-4d1a-a0fb-51eac34d780a
  modified: 2026-08-05T20:59:30.963Z
---

**Channel:** `#biztech-automations-support` (Slack channel ID `C01CBJW8M16`).

**Mechanism:** post a message mentioning the support subteam (`<!subteam^S03UN81PXHA>`) using this template:

```
Hello @[subteam]
Priority: [Low/Medium/High]
Impacted Automation: <ProcessName>
Issue: <what's failing, verbatim error if known>
Impact: <how many items/orders stuck, how long it's been failing>
Recommendation/Asks: <what you want done>
```

"BizTech Automation Support Bot" (Slack user `U06SD6MHGGH`) watches the channel and auto-creates a Jira ticket (`BT-XXXXX`) from the message content within seconds — the Jira ticket's summary/description is a near-verbatim copy of the Slack message.

**How to apply:** when the user asks to "open a chamado" for a failing BenOps automation, draft this exact template (use `slack_send_message_draft` so the user can review before sending — don't auto-send), then once they send it, the corresponding `BT-XXXXX` ticket key will show up as a bot reply in the thread — fetch it from there or ask the user for the ticket link to continue the investigation in Jira.
