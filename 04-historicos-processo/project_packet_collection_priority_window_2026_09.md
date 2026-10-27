---
name: project-packet-collection-priority-window-2026-09
description: "Packet Collection Priority Window (EOY milestone) started 2026-09-11, tracker generates 2026-09-18, queue-clearing split between Oscar/Dio/Harinath"
metadata: 
  node_type: memory
  type: project
  originSessionId: ad9b07e4-5e4d-48fa-9cb0-2f21e7b81638
  modified: 2026-09-11T16:52:26.815Z
---

Oscar declared 2026-09-11 the start of the **Packet Collection Priority Window** (first EOY milestone). The 1/1 tracker generates on **2026-09-18** — until then, no open/in-progress Packet Collection ticket should remain unresolved, and all Packet Collection bot triggers/queues need to run consistently.

Oscar, Diogenes, and Harinath Reddy Mora split ownership of the Packet Collection processes for daily queue-clearing + trigger health checks during this window (screenshot with the exact split shared in thread, not transcribed here — Oscar's message: "I'll take these, and the rest belong to Automation Ops"). Dio confirmed "yes, it's fine to me"; Harinath confirmed "Done!".

**Why:** EOY packet collection readiness is a top organizational priority for BizTech BenOps this cycle — Oscar (priority contact) is driving it directly.

**How to apply:** Until 2026-09-18 (and likely through the collection period after), treat any open Packet Collection ticket/bot (e.g. Guardian [[project_bt74025_guardian_packetcollection]], Beam [[project_bt75366_beam_packetcollection_renewal_year]], BCSA/Kaiser packet processes) as elevated priority — surface these first in `/morning` and `/followup`, and flag if a Packet Collection queue/trigger looks unhealthy even without an existing ticket. Source thread: Slack channel C0C1AKUUKED (group DM with Oscar + Harinath), thread ts 1789143810.511579, 2026-09-11.

**Dio/Automation Ops queue assignment (confirmed by Dio 2026-09-11, from the split screenshot):** `Anthem_Packets`, `BCBS_IL_Packets`, `BCBS_MA_Packets`. Oscar owns the rest (not enumerated).

**2026-09-11 health check on the 3 assigned queues (Production, via `uip or jobs list`/`triggers list`):**
- **Anthem_Packets** (`Advising_Anthem_PacketCollection`): faulted 09:00→12:33 (ran 3.5h before dying), left a 345-item backlog. Dio kicked off a manual run ~16:37, in progress — informed Oscar. Watch for repeat faults; a 3.5h-then-fault pattern smells like a mid-run hang, not an instant error — needs a deeper look if it recurs.
- **BCBS_IL_Packets**: healthy, ran clean same day 13:01-13:24.
- **BCBS_MA_Packets**: looked stuck at first glance (no run since 2026-09-03) but is NOT broken — see [[feedback_check_cron_before_flagging_stuck_trigger]].

**ENCERRADA (20/10/2026):** a janela acabou e Dio fechou o ticket BBO-3914 ("EOY Support work for Packet Collection Bots", Done). Não tratar mais Packet Collection como prioridade elevada por causa da janela; processos seguem normais. Próximo da fila do Oscar: [[project_bt76855_advising_uhc_packetcollection_object_reference]].
