---
name: project-bt74133-bcbs-ma-add-dependent
description: "BT-74133 BCBS_MA_NewHireEnrollment \"Add Dependent\" click failure — root cause found, branch created, fix not yet implemented"
metadata: 
  node_type: memory
  type: project
  originSessionId: 93fdb1e7-15ee-40f8-9a27-a06e7b9e7d1c
---

BT-74133 (Bug, Low priority, reported by Sri, assigned to Diogenes) — `BCBS_MA_NewHireEnrollment` fails clicking "Add Dependent" for certain transactions. Root cause found via Orchestrator log investigation (2026-07-09); branch created but fix NOT YET implemented — user is debugging it live in Studio.

**Impact confirmed in Production (`Benefits` folder, queue `BCBS_MA_NewHireEnrollment`):** 4 distinct stuck transactions, one retried daily for 10 days without success:
- `500R7000011JEJ9IAO` (Group 8105911) — 2026-06-23 → 2026-07-05, 10 retries
- `500R7000010t9tRIAQ` — 2026-06-21 → 2026-06-23, 3 retries
- `500R7000011J3qoIAC` — 2026-06-23 → 2026-06-26, 4 retries
- `500R7000012DCBRIA4` (Group 8107287) — 2026-07-02 → 2026-07-07, 5 retries

**Root cause:** `Processes/Benefits/CarrierAutomations/MemberSubmission/BCBS_MA/BCBS_MA_NewHireEnrollment/ProcessLayer/SelectPlan.xaml`, lines ~691-841. When benefit=Dental and `planCount<3`, code tries a direct `Click` on the single plan radio (`selectedPlanKey` INPUT, no idx). If that click throws, `Catch` sets `HasDentalPlan=True` and logs `"Medical and Dental plans processing"` (this exact log line appears in all 4 failing transactions, confirming the branch). Downstream, `If Condition="[HasDentalPlan]"` → `Then` → `Else` (dependents exist) calls `Invoke EnterDependentsInformation workflow` directly with **zero `Click 'Next'` beforehand** (line 834), unlike the parallel non-exception path (line 852-912) which clicks 'Next' first to navigate from Plan Selection page to Persons Covered page. Result: `EnterDependentsInformation.xaml` runs while still on the Plan Selection page, so `<webctrl tag='A' aaname='Add Dependent'/>` isn't found (closest UI matches are generic admin-nav elements, confirming wrong page).

**Fix CONFIRMED WORKING end-to-end (2026-07-09, 16:12:21):** queue item `500R7000012DCBRIA4` ran `Successful` in Staging after fix v2. History of the fix:
- **v1** (didn't fully work): added `Click 'Next'` (selector `<webctrl tag='H3' aaname='Plan'/><nav up='3'/><webctrl tag='A' aaname='Next'/>`, same as the working path's `Click_24`) inside `HasDentalPlan=True` → dependents-exist `Else` branch, right before `InvokeWorkflowFile_4`. This alone wasn't enough — for the single-Dental-plan case, `planCount=0` (literally zero plan radios, not "1") because the portal auto-advances straight to the "Persons Covered" page with nothing to click. v1's own `Click 'Next'` then failed too, searching for the now-gone "Plan" H3 heading (closest match: "Persons Covered" 61%).
- **v2** (works): added a `UiElementExists` guard for `<webctrl tag='H3' aaname='Persons Covered'/>` (reusing the exact selector already proven in `Click_78`) before attempting the `Click 'Next'`. If already on Persons Covered → skip the click, invoke `EnterDependentsInformation` directly. If still on Plan page → click 'Next' as in v1.
- Added diagnostic `LogMessage` activities (`LogMessage_BT74133_*`, `UiElementExists_BT74133_1`) logging `errorExistsonPage`, `notEnrolled` ("Please select benefits" screen), `planCount`, and `alreadyOnPersonsCoveredPage` at each stage — these were essential to diagnosing v1's residual failure and should stay for future debugging (ticket-prefixed names, harmless if left in).
- `validate` and `build --skip-analyze` both clean. Full `build` still fails project-wide on pre-existing unrelated `UI-DBP-006` errors (systemic to legacy UI-heavy processes, confirmed also on `Anthem_NewHireEnrollment` — see [[feedback_local_debug_folder_binding]]).

**Branch:** `BT-74133-BCBS_MA-NewHireEnrollment-add-dependent-click-fix`, created off up-to-date `origin/develop` (2026-07-09). No PR yet.

**Before opening PR:** CLAUDE.md pre-PR checklist wants 2-3 tested transactions — only 1 confirmed so far (Karmacharya/DCBRIA4). The other 3 recreated Prod transactions (JEJ9IAO, t9tRIAQ, J3qoIAC) all hit "EE already exists in carrier portal" in Staging before even reaching this code path — Staging sandbox doesn't reset, so reused real Prod employee data risks this. Checked ~13 more recent Prod Failed transactions (2026-06-21 to 2026-07-08) — none had dependents>0 with this exact "Add Dependent" signature; they're all unrelated failures (group not in portal, unexpected effective date, already exists). No more known-good repro candidates found — user decided to stop searching and proceed with the 1 confirmed transaction.

**Committed (2026-07-09):**
- `4e0ee87f1` — the SelectPlan.xaml fix + diagnostic logs
- `008e4ba13` — project.json version bump 6.0.8 → 6.0.9
- Both on branch `BT-74133-BCBS_MA-NewHireEnrollment-add-dependent-click-fix`, not yet pushed/PR'd.

**Published to Orchestrator Staging (2026-07-09):** packed via `uip rpa pack --skip-analyze` (full analyze still blocked by unrelated pre-existing `UI-DBP-006` errors), uploaded via `uip or packages upload`, then `uip or processes update-version <processKey> --package-version 6.0.9 --folder-path "Benefits"` (process key `4359C196-17DF-4DDD-B87A-04A8C04B996C`, folder `Benefits`/FolderId 48382 — this is the actual binding, distinct from the queue's shared `Benefits/CarrierAutomation` folder). Confirmed `IsLatestVersion: true` after update.

**PR opened (2026-07-09):** [#2920](https://github.com/Gusto/biztech-uipath-rpa/pull/2920), branch pushed and merged with `origin/develop` first (per Buildkite two-dot-diff rule — brought in unrelated Kaiser_CA/MN_PFML_Audit merges that had landed on develop after the branch was created). Diff vs `origin/develop..HEAD` confirmed clean: only `SelectPlan.xaml` + `project.json`.

**Buildkite failure + fix (2026-07-09):** `check_dependency.sh` failed — "Please upgrade Gusto_Benefits to version 1.552.8" (process was pinned to 1.550.12, stale vs. what other PRs had already bumped on develop). Bumped `project.json` dependency to 1.552.8, projectVersion 6.0.9 → 6.0.10, re-packed, re-published to Staging (folder `Benefits`, same process key `4359C196-17DF-4DDD-B87A-04A8C04B996C`).

**Re-validated after lib bump (2026-07-09):** confirmed twice that the fix + new Gusto_Benefits version work together with zero selector/click errors:
1. Real unattended Orchestrator job (`fc4c4b23...`, ran on `ROBODV1-PRD-AWS`, 5m17s, job State `Successful`).
2. Studio Debug re-run of the same `500R7000012DCBRIA4` — ran clean end-to-end, no code error. Queue item showed `Failed` only due to "EE already exists in carrier portal" — expected, since this same employee had already been fully enrolled by the earlier successful test run (2026-07-09 16:09-16:12) in the same Staging sandbox. Not a regression.

**Commit `063c39f40` pushed (2026-07-09)** with the Gusto_Benefits 1.552.8 bump — Buildkite passed ✅. PR #2920 green, pending review/merge only. If further clean-employee testing is needed, must pull a genuinely fresh transaction (this Group 8107287 employee is now "used up" in Staging).

**Reminder for next time:** after making a fix change post-PR-open (e.g. reacting to a CI failure), don't forget to actually `git commit` + `git push` it — easy to test/fix locally and forget the commit step since Staging publish doesn't require git at all.

**Why:** pre-existing bug, not from a recent PR (`SelectPlan.xaml`'s last logic change was the Windows migration in #2570) — only triggers on the specific combo Dental + ambiguous/single plan radio + employee has dependents.

**Staging test setup:** recreated the exact failing Prod transaction (`500R7000012DCBRIA4`, Group 8107287, Dental+Medical+3 dependents) as a queue item in Staging `BCBS_MA_NewHireEnrollment` (folder `Benefits/CarrierAutomation`), isolated the queue (deleted 19 unrelated old New items), item currently `New` ready for retest.

**How to apply:** when resuming, check `git diff` on `SelectPlan.xaml` / `git log` on this branch to confirm the fix is still there before re-diagnosing. Re-test with the recreated queue item above (recreate again via the same SpecificContent if it got consumed — see [[feedback_staging_queue_items]] for the exact-field-name rule). Don't re-run the full log investigation — root cause already confirmed against 2 independent transactions' logs plus a live reproduction.

Related: [[feedback_orchestrator_job_trigger]], [[uip_rpa_cli_reference]].
