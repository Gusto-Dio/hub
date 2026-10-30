---
name: project_bbo3937_thomas_walkthrough_script
description: BBO-3937 roteiro em inglês pro walk-through com Thomas (Feature 1 story 1) + estado do trabalho em 30/10 e o que retomar
metadata:
  node_type: memory
  type: project
  originSessionId: b219ea53-c110-44ff-b2a3-1aff152adcc5
  modified: 2026-10-30T02:46:33.466Z
---

Walk-through da BBO-3937 com Thomas (Dio retoma em 31/10). Ver [[project_bbo3937_slo_alerting_quality_layer]] e [[reference_slo_measure_scripts_ahsen]].

**Talking points (EN):**
1. The Quality Layer SLO Finetuning doc is split into 3 features, one page each. Thomas picked Feature 1 (SLO Rules and Slack Routing) first. Features 2 (Alert to Ticket Flow) and 3 (Triage) stay in backlog.
2. Feature 1 has 8 stories. Story 1 is done locally: fine-tune of the slo.yaml of the 3 pilot packet-collection bots (Anthem, BCBS_IL, BCBS_MA).
3. Data: a PowerShell collector (Measure-PilotBot.ps1, adapted from Ahsen's scripts) reads queue items and jobs from the Production Orchestrator with the uip CLI, read-only, counts only, no customer data. 91 days requested; effective 55 days of queue items for all 3 bots, jobs from 2026-09-28 for Anthem and BCBS_MA (91 days for BCBS_IL).
4. Changes: error_rate, error_count and execution_time set from the baseline (warning near p95, critical above the worst day seen). BCBS_MA error_rate removed (100% failure every active day, 576 of 599 are BusinessException). throughput and staleness untouched.
5. Testing: slo_validate.sh passes on all 3 files. An evaluator/backtest (slo_eval.py) reads the real slo.yaml files (old from origin/develop vs new) and replays them over the daily counts. Alert episodes per 30 days, old -> new: 15.9 -> 7.4 without throughput/staleness; 29.2 -> 20.7 with them. The model gives ~29 vs ~32 real alerts per month.
6. Not proven: the Datadog side. Nothing fires alerts locally; the monitors are created by slo_sync.sh in CI only after merge to develop. Question for Thomas: how do we test the monitors before wiring the real channel (shadow mode / test channel / Datadog backtest)?
7. Backlog: throughput needs queue depth (~65-70% of today's noise), system vs business error split, owner_group and Slack routing via owner-map.yaml, 91 dead monitors, rest of the fleet, then Features 2 and 3.

**Decisions needed from Thomas:** the test design; approval of the PR. **From the process owner (Jack):** Anthem execution_time 4h -> 9h (32400s).

**Correction to remember:** there is no "script that fires". Two scripts: collector + evaluator. Say "story 1 of Feature 1 is implemented and validated locally", not "Feature 1 is done".

**State at end of session (30/10):** local commit 9860063e0 on BBO-3937-slo-feature1-rules-and-slack-routing (no push, no PR). Clone is currently on BT-77264 branch. Hub (C:\Projects\hub, 03-tools/scripts/slo-measure) has uncommitted collector, evaluator and README; README does not yet list slo_eval.py. Verify the commit contains the final values (compare with the evaluator's numbers) before the PR.

**Why:** Dio presents this to Thomas before any PR.
**How to apply:** next session, offer the English Jira status paragraph (draft not posted), the shadow-live decision (manual vs Scheduled Task, needs explicit approval), update the hub README, then wait for Thomas's approval before PR. No push/PR/post without Dio's order.
