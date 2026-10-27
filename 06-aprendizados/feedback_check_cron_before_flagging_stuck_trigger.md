---
name: feedback-check-cron-before-flagging-stuck-trigger
description: "A long gap between packet-collection runs isn't proof of a dead trigger — check the actual cron days before escalating"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: ad9b07e4-5e4d-48fa-9cb0-2f21e7b81638
  modified: 2026-09-21T16:47:58.230Z
---

Some Packet Collection processes (e.g. `BCBS_MA_PacketCollection`) intentionally run only on specific billing-cycle days — cron like `0 0 22 1,2,25,27,28,29,30,31 * ? *` (month-end/month-start only). An 8-day gap since the last run looked like a dead/disabled trigger on 2026-09-11, but `uip or triggers list` showed it `Enabled: true` and the last run matched the schedule exactly (day 2 fire); the next legitimate fire wasn't due until day 25.

**Why:** Packet collection carriers batch their portals around billing cycles, so several of these processes are deliberately sparse — not every carrier process runs daily like the "Advising_*" ones do.

**How to apply:** Before flagging a Packet Collection (or any scheduled) process as "trigger broken" from job-history gaps alone, always pull the trigger's `StartProcessCron` via `uip or triggers list --type time --folder-key <key> -n <name>` and check whether the gap matches the cron, not just eyeball days-since-last-run. Only escalate if the gap falls outside the scheduled days AND the trigger is enabled.

**Additional layer (per John Falk, 2026-09-14ish, relayed 2026-09-21):** `BCBS_MA_PacketCollection` is owned by the **AOps team**, not BenOps — Dio's EOY-window responsibility for it (per the Oscar split, [[project_packet_collection_priority_window_2026_09]]) is just queue/trigger health monitoring, not dev ownership. Also, BCBS_MA packets are only available on the carrier portal starting ~60 days before the plan's effective date — so for the 1/1 EOY cycle, expect near-zero items until roughly November even on scheduled cron-fire days. A low/zero item count in Sept-Oct is expected seasonality, not a bug, separate from (and in addition to) the cron-day gating above.
