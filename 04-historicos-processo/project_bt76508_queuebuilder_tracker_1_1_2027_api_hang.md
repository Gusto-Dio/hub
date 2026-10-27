---
name: project-bt76508-queuebuilder-tracker-1-1-2027-api-hang
description: "BT-76508 Advising_Packet_Collection_QueueBuilder faults since 9/30 because the \"REN: Packets - 1/1/2027\" tracker spreadsheet does not answer the Google Sheets API most of the time; code fixes tried and discarded; messages sent 10/07-08, waiting for replies"
metadata:
  node_type: memory
  type: project
  originSessionId: 5a2daf1e-b5eb-4b13-ae44-3218441f6067
  modified: 2026-10-08T02:21:06.080Z
---

BT-76508 (EM ANDAMENTO, status em 2026-10-08): QueueBuilder (Prod, folder Benefits, v1.6.5, key 437EE2CD-...) faults every run since 9/30; queues for Anthem/BSCA/BCBS IL/Oxford not filled (BBO-3914, John Falk).

**Confirmed (timing + direct tests):**
- The MarkCanceled error is a symptom: each failing ReadRange hangs ~100 s (default HTTP timeout); 3 attempts + 2x15 s = ~331 s per carrier. Not an HTTP 409 (that would return in ~1 s). Inner exception is "none".
- Only hub row 1, tracker `1z5NdEsZidA60WSZJgTLpPfHFtZe71axLhCgLQzmx5eA` ("REN: Packets - 1/1/2027"), hangs. 11/1/2026 (`1PYrau98awyJQlBVJ0xo_spv1NiY2ej9146aZr7t15Is`) and 12/1/2026 (`1VjRMg6K5BRMHxo_oi7T1-mMsdA-up3DqHTfFq5mDvwE`) answer in <1 s. Seen from the VDI Studio (Diag_ReadTest: tiny A1:A1 and full tab both fail on 1/1/2027), via the MCP Sheets connector, and via raw REST `values.get` with the service-account token. Monitor 01:39-01:57 on 10/08: 32/36 hangs on 1/1/2027 (one ~2 min good window), 0/36 on 12/1/2026. Opens normally in the browser; browser xlsx download ~1 min; one-tab CSV download fast, but programmatic CSV export also hung on some tabs (500/429 too).
- Each carrier reads all 3 hub rows, so one bad tracker fails the whole carrier.
- Service account: uipath@biztech-natural-language-proc.iam.gserviceaccount.com (key path in asset Asset_GoogleServiceAccountKeyPath). Hub workbook `1umJ-irwckTvsD-4w_eXR-3ahsFNZamSuoQ8i-ymAneA`, tab IDs. Staging robots cannot read the key file share (job fails "Key file not found"); only the VDI Studio can.
- 1/1/2027 tracker is bigger (~2.5M cells vs ~1.6M for 12/1; bot_master 15k rows, redash_raw 24k, Guardian 11k) but size alone does not explain it.

**Not known:** why the file stalls for the API (suspects: recalculation, scripts/imports, lock contention, a writer hogging it). Leaning Category of Break = Data Issues (INFRA ISSUE if it turns out to be Google-side).

**Tried and discarded:** GSuite scope TimeoutMS (ignored); Pick(ReadRange vs 30 s Delay) -> "threw or propagated an exception while being canceled", not catchable, no retry; local download / CSV export workaround (also hangs); HTTP GET replacement (also hangs, retry would land in the same bad window). Branch BT-76508-queuebuilder-read-diagnostics was reverted to develop (nothing committed or pushed); only untracked Diag_ReadTest.xaml and entry-points.json remain. Pick/diag patch existed only in the session scratchpad.

**Communication done (2026-10-08):** user posted in Slack (channel C0ANAPHL1NE, thread ts 1791425462.353319) to Oscar/team the findings plus 2 questions: has anyone seen this before, and OK to test with a copy of the tracker (shared only inside Gusto, deleted after). The user removed my question about dropping the 1/1/2027 hub row and did not include the "who owns it / what changed ~9/23" question (suggested as a follow-up). Message to John Falk was also sent (no copy of its final text saved). No replies yet when last checked. Nothing posted to Jira.

**Status at end of 2026-10-08 session:** waiting for the team's reply on Slack; user wants to document the failed attempts (Pick, GET, ReadRange, API) — a short plain-text Slack version and a longer English Jira-style table were drafted but NOT posted; user prefers short, no-formatting Slack messages. User will resume the next day.

**Pending / next steps:**
- Wait for replies (Oscar, team, John); optionally follow up with owner / what changed ~9/23.
- If a copy of the tracker is made: share it read-only with the service account, run the monitor (read-only values.get A1:A1 every 30 s, 20 s timeout, scripts were in session scratchpad, venv with cryptography+requests) against the copy to tell "original degraded" from "content too heavy". Production reads with the service account need explicit user approval each time (auto mode blocks them).
- Set Category of Break (Data Issues leaning) and post English Jira comments on BT-76508 and BBO-3914 only after the user reviews them.
- Cleanup: Staging Process Advising_Packet_Collection_QueueBuilder was left bound to 1.6.6 (was 1.6.4; 1.6.6 only adds an ineffective TimeoutMS) — rebind back needs explicit approval. The uip CLI active tenant was restored to Staging.

**Why:** the cause is on the spreadsheet side, so code-only fixes do not recover reads.
**How to apply:** resume from "Pending" above; do not retry timeout/Pick/CSV/GET ideas. Related: [[feedback-gsuite-readrange-not-cancel-safe]]
