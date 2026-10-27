---
name: project-bt76074-uhc-sam-terminations-queue-split
description: "BT-76074 — UHC Terminations SAM/SAMx split fixed; TICKET CLOSED (Done/Resolved), confirmed active in Production"
metadata:
  node_type: memory
  type: project
  originSessionId: 01975257-31a8-44c8-a569-940bd5c44699
  modified: 2026-09-30T19:54:29.467Z
---

Ticket BT-76074 (reported by Tammy Borders, 2026-09-24): the `UHC_SAM_Terminations` Orchestrator queue keeps getting built with cases that should go to `UHC_SAMx_Terminations`. The SAM bot is deprecated, so items stuck there never process. 5 cases reported in the ticket; 7 confirmed stuck in Production as of 2026-09-29 (queue id 30345, `TotalNumberOfTransactions: 0`).

**Root cause — two pieces, both needed to fix:**
1. `Processes/Benefits/CarrierAutomations/MemberSubmission/QueueBuilder/Queries/UHC_SAM_Terminations.soql` is still live in the `Queries/` folder. `QueueBuilder` builds one Orchestrator queue per `.soql` file found there (`Main.xaml` ~line 201, `Directory.GetFiles`), so it keeps generating the dead `UHC_SAM_Terminations` queue and routing any case whose `MF_Group_Number__c` contains a letter (A–Z) into it.
2. The sibling `Queries/UHC_SAMx_Terminations.soql` has 26 `(NOT MF_Group_Number__c LIKE '%X%') AND` clauses (one per letter) that exclude any group number containing a letter — so even if the SAM queue stopped being built, those same cases would never be picked up by SAMx either (silently dropped, not just misrouted).

Confirmed live example: Production queue item `GroupNumber: "09Q6960"` (contains `Q`) — matches the alpha-exclusion pattern exactly.

**Carrier_Id is already correct in SAMx Terminations** — line 14 of `UHC_SAMx_Terminations.soql` already reads `(Carrier_Id__c = '60' OR Carrier_Id__c = '45')`. No carrier-id change needed there (I initially assumed it needed widening from `'60'` only, like the NewHireEnrollment precedent — that was wrong, caught by the user asking "how do you know carrier ids are 45/60" — always re-verify assumptions against the actual file content before proposing a diff). Only the SAM file (still `Carrier_Id__c = '60'` only) has the narrow carrier filter, and it's being deleted/backed-up, not edited.

**Precedent (exact pattern to mirror):** commit `7abd8bad8f9` "transit uhc sam to samx" (#2522, Ahsennur, 2026-04-10) did this identical fix for `NewHireEnrollment`: moved `UHC_SAM_NewHireEnrollment.soql` out of `Queries/` (renamed to `..._oldQueryBackup.soql`, placed at project root) in both `QueueBuilder` and `SF_Updater`, stripped the 26 letter-exclusion clauses from `UHC_SAMx_NewHireEnrollment.soql`, and kept a backup of the pre-change SAMx query too. Terminations was simply never migrated when NHE was. `UHC_SAM_MemberUpdates.soql`/`UHC_SAMx_MemberUpdates.soql` still have the same unresolved split — same latent bug, NOT in scope of BT-76074, flagged for a separate ticket.

**Fix plan (not yet implemented, no code changed):**
In both `QueueBuilder/` and `SF_Updater/` (files are byte-identical between the two projects):
1. Move `Queries/UHC_SAM_Terminations.soql` → `UHC_SAM_Terminations_oldQueryBackup.soql` at project root.
2. Remove the 26 `NOT MF_Group_Number__c LIKE` clauses from `Queries/UHC_SAMx_Terminations.soql` (leave carrier-id clause untouched).
3. Back up the pre-change SAMx query as `UHC_SAMx_Terminations_oldQueryBackup.soql`.
4. Bump `projectVersion`: QueueBuilder `3.14.4`→`3.14.5`, SF_Updater `1.17.3`→`1.17.4`.
5. Both changes (remove SAM query + widen SAMx query) must ship together — removing only the SAM query silently drops alpha-group cases from all queues; widening only SAMx while SAM still active causes duplicate processing of the same case in both queues.
6. The 5–7 cases already stuck in Production's dead `UHC_SAM_Terminations` queue won't self-heal from this fix (Salesforce case status won't re-trigger the query) — need manual cleanup/requeue after deploy, separate from the PR.

**Sheets tracking:** BT-76074 not found in the "RPA BenOps Nov 2025" tab — `_sheets_not_found = true`, needs manual Status/Dev Start Date update.

**Status as of 2026-09-30: fix implemented, PR #3384 open against develop, E2E validated live in Staging.** Branch `BT-76074-uhc-terminations-samx-only` off develop. Commit `1f93922f284`. Applied the fix plan exactly as above in both projects.

**Buildkite pre-flight checks done before opening the PR** (per [[feedback_check_version_bump_before_pr]]): confirmed live Production `ProcessVersion` via `uip login tenant set Production` + `uip or processes list --all-folders -n <name>` — `MemberSubmissions_QueueBuilder` was 3.14.4, `MemberSubmissions_SF_Updater` was 1.17.3, both lower than the bumped versions (3.14.5/1.17.4), so `check_version.sh` passes. Both projects have `"skipTests": ["update_dependency"]` in `settings.json`, so `check_dependency.sh` is a no-op regardless. Switched back to Staging tenant immediately after the Production read, per standing practice.

**E2E validated live in Staging (2026-09-30), not just packed/uploaded:** `uip or packages upload` alone does NOT make Orchestrator jobs use the new code — the Staging folder's bound Process version was still old (QueueBuilder 3.11.1, SF_Updater 1.14.1) after upload. Had to explicitly run `uip or processes update-version <processKey> --package-version <new>` to rebind the Staging processes to 3.14.5/1.17.4 before `jobs start` would actually exercise the fix. This action was blocked once by the auto-mode classifier as "Production Deploy" even though the target was the Staging tenant — needed explicit user approval to proceed (classifier didn't distinguish tenant). Left the Staging processes pointed at 3.14.5/1.17.4 after the test (not rolled back) since that's the correct target state anyway.

Ran both jobs via `uip or jobs start` (never `uip rpa run`, per [[feedback_orchestrator_job_trigger]]) — each took ~3-12 min since QueueBuilder/SF_Updater iterate through every carrier's queue-building query sequentially, not just UHC's. `MemberSubmissions_QueueBuilder` job → **Successful**: 24 new items landed in `UHC_SAMx_Terminations` (baseline was 0 new/8 total), including real live cases with a letter in `GroupNumber` — `06X0956` (x3), `09Q6960` (x2, the exact group number flagged as a stuck Production example during investigation), `HP6350257525B`. `UHC_SAM_Terminations` stayed at 0 items throughout — confirms the dead queue is no longer fed. `MemberSubmissions_SF_Updater` job → **Successful**, no errors.

**PR #3384 merged 2026-09-30 (16:24 UTC).** Buildkite autodeploy published both packages to the Production feed (`MemberSubmissions_QueueBuilder:3.14.5`, `MemberSubmissions_SF_Updater:1.17.4`, both `IsLatestVersion: true`) but — exactly as [[feedback_buildkite_production_deploy_only_feed_not_process]] predicted — did NOT rebind the Process versions. Checked via `uip or processes list --all-folders`: Process bindings were still on the old versions (3.14.4 / 1.17.3) right after the Buildkite run. User (Dio) manually rebound both Processes in the Orchestrator UI. Re-checked and confirmed both Processes now show the new version with `IsLatest: true` — fix is actually active in Production, not just sitting in the feed.

**TICKET CLOSED 2026-09-30** — Jira status moved to Done, resolution Resolved (user closed it directly).

**Still open / not covered by this ticket:** manually requeue/clean up the 5–7 cases stuck in Production's dead `UHC_SAM_Terminations` queue — never part of this PR's scope, still pending as loose thread if it resurfaces later.
