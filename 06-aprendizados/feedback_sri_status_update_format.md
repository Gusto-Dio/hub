---
name: feedback_sri_status_update_format
description: "Format for async status updates to Sri in #usp-rpa-benops-support-dev, modeled on Ahsen's messages"
metadata: 
  node_type: memory
  type: feedback
  modified: 2026-08-21T15:03:29.191Z
  originSessionId: 03462ee0-2680-4839-9b1f-106535eea2f8
---

Sri's status updates in `#usp-rpa-benops-support-dev` (channel ID `C0ANAPHL1NE`) follow a consistent, lightweight pattern — copy this shape instead of inventing a new one.

**Why:** user asked (2026-08-21) to prepare their own status "no mesmo padrão que a Ahsen fez", pointing at a specific message from Ahsen Turksoy as the reference (thread `p1787320636468559` in that channel).

**Format (from Ahsen's example):**
```
hi team, <@U07KMNHHFB6|Sri Perinkolam>, updates:
<one line per item — plain sentence, no bullet marker, what happened/changed>
<optional celebratory emoji line summarizing overall progress, e.g. :cat_tada_celebrate: ... :cat_tada_celebrate:>

<Jira link 1> done
<Jira link 2> in progress
<Jira link 3> to do
```

**How to apply:**
- Tag Sri with the exact mention format `<@U07KMNHHFB6|Sri Perinkolam>` so it renders as a real mention.
- Narrative lines are short, plain-English sentences — no markdown bullets, no headers.
- Ticket list at the bottom uses real Jira links (`<https://gustohq.atlassian.net/browse/BT-XXXXX|BT-XXXXX>`) each followed by a terse status word/phrase (`done`, `in progress`, `to do`, `blocked`) — not a full sentence.
- Keep it to the handful of tickets with actual recent movement, not the entire open-PR backlog (see [[work_state]] for the full list) — Ahsen's example covered ~5 items.
- Language: English (Slack messages rule applies, per [[feedback_language_jira_prs]] which covers Jira/PR — same rule extends to Slack per project CLAUDE.md).
- Always draft first and show the user before sending (established pattern this session) — use `slack_send_message_draft` to park it in the channel's Drafts & Sent instead of sending immediately, so the user can review/edit in Slack before it goes out.
