# Team and channels

Team: benadmin-automation (formerly BizTech / BenOps RPA). Source: Notion "BenAdmin Automation Hub" (R&D Teams / Benefits R&D), last edited 2026-10-28, plus roles seen in tickets and PRs.

## Priority contacts (confirmed by Dio, 2026-10-29)
Sri Perinkolam (PM), Thomas Taylor (tech lead), Oscar Nuñez and Jonathan. Messages, tickets and PR comments from them go first in `/morning` and in any triage. If one of them mentioned Dio, commented on one of Dio's PRs, assigned a ticket, or asked for validation, it goes to the top of the day's list.

| Person | Role | Notes |
|---|---|---|
| Sri Perinkolam | PM | Receives async status updates (`feedback_sri_status_update_format`); Slack mention `<@U07KMNHHFB6|Sri Perinkolam>` |
| Thomas Taylor | Tech lead | Owns the Buildkite dependency/lock checks; asks for full bot tests when a lib changes |
| Oscar Nuñez | Team member | Approves PRs in the order Dio asks for; Dio merges his own PRs |
| Jonathan | Priority contact | Surname and role not recorded; fill in when known |

## Rest of the team
| Person | Role | Notes |
|---|---|---|
| Hari Reddy Mora | Team member | Published several current Production versions |
| Ahsen Turksoy | Team member | His status messages are the model for Sri updates |
| Ike Ofili | Team member (listed as tech lead in Notion) | |
| Josh Hogsett | Team member | |
| Vinh Lu | Team member | |
| Diógenes Ribeiro (Dio) | Team member | The user of this hub |

Ticket requester (not on the team): Bri, on UHC/BCBS items; surname not recorded.

## Channels
| Channel | Use |
|---|---|
| `#biztech-automations-support` (`C01CBJW8M16`) | Where support tickets for our automations are opened. Post the template mentioning `<!subteam^S03UN81PXHA>`; "BizTech Automation Support Bot" creates the Jira BT ticket from the message (`feedback_slack_automation_support_ticket_template`). Keeps the old "biztech" name. |
| `#usp-rpa-benops-support-dev` (`C0ANAPHL1NE`) | Async status updates to Sri. Draft first, never auto-send. |
| `benadmin-automation-dev` | Squad Connect, developers only |
| `benadmin-automation-squad` | Squad Connect, with PEs |

Slack messages are sent in English, only to approved internal channels (`../00-rules/security.md`). Never post to external or Connect channels that are not the two squad channels above without asking.

## Links
- Repo: `https://github.com/Gusto/biztech-uipath-rpa` (default branch `develop`)
- Orchestrator: `https://cloud.uipath.com/gustoinc/Production/orchestrator_` (org `gustoinc`; default tenant for work is Staging)
- Jira: `gustohq.atlassian.net` (cloudId rule in `reference_jira_cloudid`); board `https://gustohq.atlassian.net/jira/dashboards/10203`; epic filter `https://gustohq.atlassian.net/issues/?filter=33517`
- Notion hub: "BenAdmin Automation Hub" (synced daily by `/benops-sync`)
- Skills repo: `github.com/Gusto-Dio/benops-rpa-skills` (plugin `benops-rpa`, CLAUDE.md template at `templates/CLAUDE.md.template`)
- Bots tracking sheet: `reference_benops_bots_tracking_sheet`

## Ceremonies (Notion)
Standup Tue and Thu; async updates Mon and Wed; Friday no meetings; sprint retro, grooming and planning bi-weekly; monthly team get-together.
