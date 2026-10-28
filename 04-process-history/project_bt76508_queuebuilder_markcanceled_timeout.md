---
name: project-bt76508-queuebuilder-markcanceled-timeout
description: "BT-76508 Advising_Packet_Collection_QueueBuilder faulting since 9/23 (MarkCanceled) - analysis findings 2026-10-07; root cause NOT yet confirmed, fix proposed not applied"
metadata:
  node_type: memory
  type: project
  originSessionId: d198408c-3e2b-4cca-9360-c4dedc53c44b
  modified: 2026-10-07T21:02:40.934Z
---

Investigation (read-only, Production, 2026-10-07) of Advising_Packet_Collection_QueueBuilder (v1.6.5, folder Benefits) faulting with "Only activities which have been requested to cancel can call MarkCanceled".

**Confirmed from logs/Orchestrator:**
- Each failed carrier takes ~332s (331-339s repeatedly, across 9/25, 9/30, 10/7) = 3 attempts x ~100s + 2 x 15s retry interval. So every ReadRange attempt HANGS ~100s then is cancelled. It is NOT a fast HTTP 409 (the XAML annotation's claim is unsupported). ~100s = default HTTP client timeout; GSuiteApplicationScope has TimeoutMS = null.
- Run duration jumped 9/22 (21 min, Successful) -> 9/23 (80 min). "Successful" runs 9/28 (54 min) and 9/29 (79 min) were also slow: reads hanging then recovering on retry. Failures started on the first carrier read in the run (14:06 for a 14:00 start).
- Slowness hits all robots (ROBOT-1..6, ROBOT1-PRD-AWS), not machine-specific. No deploy (ReleaseVersionId constant). Asset_GoogleServiceAccountKeyPath never modified since 8/26 (value not read).
- Carrier tabs are small (~1000 rows x 25 cols) so sheet size is not the cause. Hub workbook IDs tab lists 3 cohort workbooks (1/1/2027, 12/1/2026, 11/1/2026); carriers loop over those.
- Concurrency theory weakened: 9/29 (good) had 75 overlapping jobs (46 Advising_UHC_PacketCollection), 9/23 (bad) only 21, 9/22 (good) 10.
- Robot log level is Info: `uip or jobs logs --level Trace` returns 0 rows, so the real underlying exception is NOT in Orchestrator logs. Need to log exception.ToString/InnerException in a Catch to learn it.

**Not confirmed:** what Google/network error is behind the cancel (suspects: egress/proxy/TLS stall from robots to sheets.googleapis.com, long-lived GSuiteApplicationScope reusing a dead connection across ~39 reads with 20s delays, token fetch stall, activity package version).

**Proposed fix (not applied):** move GSuiteApplicationScope inside the loop (fresh connection/token per read) or at least per carrier; set explicit TimeoutMS (~30000) with more retries/backoff; add Catch logging full exception (InnerException); continue other carriers on failure (already done); pin the GSuite package version explicitly (QueueBuilder only gets it transitively via Gusto_Benefits 1.555.1).

**Why:** Category of Break suggested: INFRA ISSUE (not a deploy or logic regression; unconfirmed).
**How to apply:** Do not post to Jira/Slack without asking; Jira text in English. uip tenant was restored to Staging after the read. Gotchas: `uip or jobs logs` needs --limit <=100 and paging via --offset (limit 2000 gives HTTP 400); `--level Warning` also returns 400.
Related: [[feedback-uip-default-tenant-not-production]], [[feedback-production-reads-blocked-by-auto-mode]]
