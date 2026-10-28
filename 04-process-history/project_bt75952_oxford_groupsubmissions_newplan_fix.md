---
name: project-bt75952-oxford-groupsubmissions-newplan-fix
description: "BT-75952 — Oxford_GroupSubmissions_NewPlan three confirmed root causes (TAE selector race, zip fix never ported, SFDC status gap) and fix proposal"
metadata:
  node_type: memory
  type: project
  originSessionId: ce58ed67-3697-4ec5-9e26-3e2e23fe7e1d
  modified: 2026-09-23T21:03:36.892Z
---

BT-75952 (High priority, reported/assigned to Dio, 2026-09-22) — Oxford_GroupSubmissions_NewPlan failing repeatedly on the UHC SAMx portal. Investigation complete via Orchestrator Production logs first (per [[benops-ticket-investigation]] iron rule); code read only after confirming the error. Branch created: `BT-75952-oxford-groupsubmissions-newplan-fix` (off `develop`, not yet implemented/pushed).

**Three confirmed, independent root causes** (all found by reading both `Oxford_GroupSubmissions_NewPlan` and its sibling `UHC_GroupSubmission_NewPlan_SAMx` directly — git shows `.xaml` as binary, so no `git diff` across commits; compare current file content by hand):

1. **Selector timeout on "Total Applying Employees"** — `EnterCompanyInfo.xaml`, `Sequence_39` "Enter Group Details" (~line 758), `TypeInto_TAE`. `SelectorNotFoundException`, closest match 93% = `Total Eligible Employees`. Confirmed identical verbatim error on 4 Production faulted jobs (9/11, 9/12, 9/18, 9/19); 11 of last 20 scheduled runs faulted. UHC SAMx hits the *same* selector error intermittently too (confirmed 9/21) — so the field wasn't renamed, it's a page-hydration race after clicking "Group Details," present in both processes. Oxford already has the guard *pattern* earlier in the same file (`UiElementExists_GroupNameGuard` / `If_GroupNameGuard`, ~line 347, for "Group Name") — just never extended to "Enter Group Details."
2. **Zip-code dropdown fix (BT-75454/BT-75847) never ported to Oxford** — UHC SAMx's `EnterCompanyInfo.xaml` has an `NApplicationCard_10` → `NKeyboardShortcuts_1` (hardware Down+Enter) block right after the zip `TypeInto`, added to confirm the autocomplete dropdown actually selects a value. Oxford's `TypeInto_5` (~line 369) still only has the old blind `[k(enter)][k(enter)]` with no follow-up confirmation step. Confirms [[project_bt75847_uhc_samx_newplan_zip_sfdc_status]]'s finding that Oxford is a separate codebase the fix never touched.
3. **SFDC status never flips to Failed for non-BusinessRuleException faults** — `ProcessTransaction.xaml`, `If_21` (~line 2599). Oxford's condition is `exception.GetType.Name="BusinessRuleException" AndAlso ...`; UHC SAMx's (fixed in `a250055afa8`, BT-75847) is `(exception.GetType.Name="BusinessRuleException" OrElse in_RetryNumber>=CInt(in_Config.Item("MaxRetryNumber"))) AndAlso ...`. Oxford is missing the last-attempt `OrElse` fallback, so a `SelectorNotFoundException` (not a BRE) never triggers `UpdateCarrierOrder.xaml` even after retries exhaust — `Carrier_Order__c` stays stale, case never surfaces for manual review.

**Why divergence exists:** Oxford's `EnterCompanyInfo.xaml` was deliberately marked carrier-locked from UHC SAMx in commit `d068ada04b3` (BT-74369) — later UHC SAMx portal/robustness fixes stop auto-propagating to Oxford, so every future UHC SAMx `EnterCompanyInfo.xaml`/`ProcessTransaction.xaml` fix should be checked against Oxford by hand.

**Proposed fix (not yet implemented):**
- Add a hydration guard before `TypeInto_TAE` (mirror `UiElementExists_GroupNameGuard` pattern, gate on e.g. "Total Eligible Employees" input, `Throw` on timeout so it retries cleanly).
- Port the `NApplicationCard`/`NKeyboardShortcuts` Down+Enter confirmation block after Oxford's zip `TypeInto_5`.
- Add `OrElse in_RetryNumber>=CInt(in_Config.Item("MaxRetryNumber"))` to Oxford's `If_21` condition, matching UHC SAMx exactly.
- Process-level only, no Library changes.

**Sheets tracking:** BT-75952 not found in "RPA BenOps Nov 2025" (too new, created 2026-09-22) — Status/Dev Start Date not updated, needs manual entry.

**How to apply:** When implementation is picked up, work on branch `BT-75952-oxford-groupsubmissions-newplan-fix`. Test plan needs 3+ Staging transactions covering all three fixes before PR.

---

**2026-09-23 — All 3 fixes implemented and committed** (commit `19de9c1f014` on branch `BT-75952-oxford-groupsubmissions-newplan-fix`, rebased onto develop, not yet pushed/PR'd as of this note):
1. Zip-code confirmation block ported verbatim from UHC SAMx into Oxford's `EnterCompanyInfo.xaml` (after `TypeInto_5`).
2. TAE hydration guard added (`UiElementExists_TotalApplyingGuard` + `If_TotalApplyingGuard` → `Throw`), mirroring the existing `GroupNameGuard` pattern, variable `totalApplyingReady`.
3. `ProcessTransaction.xaml` `If_21` widened with `OrElse in_RetryNumber>=CInt(in_Config.Item("MaxRetryNumber"))` — exact text ported from UHC SAMx's already-Ahsen-approved final version (see [[feedback_businessruleexception_gate_is_intentional]] — this is the safe last-attempt-only fallback, not the gate-widening Ahsen rejected).

`validate`/`build` clean, 65 pre-existing analyzer errors unchanged (confirmed via baseline diff) — no new errors introduced by any of the 3 changes.

**Runtime validation via 8 Staging test transactions** (recreated via `QueueItemRecreator`, `in_FolderName=Benefits`, `in_QueueName=Oxford_GroupSubmissions_NewPlan`, run manually in Studio Desktop, not `uip or jobs start`):
- **Fix #1 (zip code): CONFIRMED working** — "Typed zip code" fired cleanly on every single test transaction (8/8), old bug never reproduced.
- **Fix #2 (TAE guard): NOT exercised** — the intermittent hydration race never reproduced across any test run, including on the exact 4 dates (9/11, 9/12, 9/18, 9/19) where it was originally confirmed in Production, and including the two exact Reference GUIDs Bri Boyer reported (`d8ea2273-d79c-423c-a2f1-e56135745deb`, `a65dd86a-5015-43d8-8fa0-a3f710705939`). Code is in place mirroring a proven pattern, but still unproven at runtime — inherent to testing an intermittent race with a small sample.
- **Fix #3 (SFDC fallback): NOT exercised** — no test transaction reached a last-attempt non-BusinessRuleException failure; the `OrElse` branch never got a chance to fire.

**Two NEW unrelated stale-selector bugs discovered during testing** (portal DOM changes, same bug class as the original BT-75952 issues, but different files/elements — out of scope for this ticket):
- `FillEmployerApp.xaml`: `<webctrl innertext='Group Name to appear on ID card*' />` no longer found (Employer Application page).
- `EnterCompanyInfo.xaml`, "Set rating structure filter" step: `<webctrl aaname='Filter Plans' tag='SPAN' />` no longer found (Plan Shopping page). Hit consistently on 3/3 of the newer (9/11–9/19) test cases, triggering the ReFramework's 3-consecutive-failure circuit breaker and aborting the whole Studio debug session each time.
- **Also observed**: on at least one recreated old test item, the portal's own Census page showed a validation error (red alert icon, all employee-count fields at 0/Total 0) even though `GetS3Census` "succeeded" and the automation proceeded to Plan Shopping without checking for it. Root cause not yet determined — could be the recreated/reused S3 census file no longer matching what the portal expects (test-data staleness, see [[feedback_test_data_must_be_real_not_borrowed]]) or a live portal-side upload regression. Not yet investigated further.

**How to apply:** Fix #1 has real runtime proof; fixes #2/#3 are code-reviewed and pattern-matched against already-proven UHC SAMx fixes but still runtime-unproven — flag this honestly in the PR description rather than claiming full validation. The two new stale selectors (and the census-zero anomaly) are likely candidates for a follow-up ticket, not blockers for this PR unless they turn out to affect the same code paths.

**PR opened: #3361** (https://github.com/Gusto/biztech-uipath-rpa/pull/3361), branch pushed. `projectVersion` bumped to `1.55.15` (Production feed already had `1.55.14` — bump avoids a package-already-exists collision on merge). Package `Oxford_GroupSubmissions_NewPlan.1.55.15` uploaded to the **Staging** feed via `uip rpa pack --skip-analyze` (the 65 pre-existing analyzer errors gate `uip rpa pack`'s own analyzer the same way they gate `uip rpa build`; real Buildkite `uipcli` treats several at Warning, not Error — see [[feedback_uip_rpa_pack_vs_real_uipcli_analyzer_severity]]) + `uip or packages upload`. No Orchestrator Process found bound to this package in any Staging folder — the 8 test transactions all ran via Studio Desktop reading the queue directly, never touching the packaged artifact, so the Staging upload is prep for the eventual Production Buildkite deploy only, not something the testing so far exercised.
