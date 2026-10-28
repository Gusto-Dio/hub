---
name: project_bt75885_uhc_samx_nhe_modern_type_of_dependent_selector
description: "BT-75885 UHC_SAMX_NewHireEnrollment_Modern faulting on \"Select Item :: Type of Dependent\" - stale selector missed by the BT-75581 DOM-restructuring fix"
metadata: 
  node_type: memory
  type: project
  originSessionId: 4ee82993-c738-42c1-a940-407626d721a9
  modified: 2026-09-22T01:09:09.191Z
---

BT-75885 (Medium, reporter Tammy Borders, assignee Diogenes) — `UHC_SAMX_NewHireEnrollment_Modern` faulting repeatedly on dependent enrollments. **PR #3353 opened (branch `BT-75885-uhc-samx-nhe-modern-type-of-dependent-selector`), Jira updated with PR link by user on 2026-09-22.**

**Root cause — confirmed from Production Orchestrator logs**: `Framework/EnterDependentInformation.xaml` had THREE stale `parentid='capture'` selectors, all from the same DOM-restructuring event already fixed for sibling files in [[project_bt75581_uhc_samx_nhe_proof_of_reason]] (PR #3334) — this file was missed from that batch:
1. `NSelectItem_1` + `NSelectItem_2` ("Select Item :: Type of Dependent", Then/Else branches) → fixed to `parentid='enrollment-demographics-start'`
2. `NSelectItem_3` ("Select Item :: Gender", dependent) → fixed to `parentid='enrollment-demographics-start'` — confirmed via live re-indication in Studio (user captured the real `FuzzySelectorArgument` showing `parentid='enrollment-demographics-start'` directly on the live SELECT element)
3. `NClick_1` ("Click :: Next", end of dependents page) → fixed to `parentid='current'` (89% fuzzy match at runtime, and `parentid='current'` is already used elsewhere in this same file for the Medical Information checks)

**Key structural finding**: in `Framework/Process.xaml`, the `idx` variable driving `in_Idx` into this file is reset to **2** (not 1) right before the `For Each Dependent` loop, and incremented per dependent. So the FIRST dependent processed already has `in_Idx=2` — meaning all three selector bugs affected essentially every enrollment with ≥1 dependent, not just "2nd dependent onward". Confirmed `idx` itself is legitimate (not the bug) because the idx-based `NSetText` fields (First/Last Name, Birth Date) at the same idx value succeeded consistently while only the `parentid='capture'` activities failed.

**Validation**: live-tested in Staging (tenant switched correctly after an early session where Studio was accidentally still pointed at Production — see [[feedback_studio_robot_connection_can_diverge_from_uip_cli_tenant]]) with 3 different real Production cases recreated as queue items:
- Multi-dependent (Wiest, 4 deps) — passed cleanly through all 3 fixed selectors; failure boundary moved past this file entirely (later hit an unrelated "Cannot find the policy" / "Error on adding employee" — likely dirty state from repeatedly resubmitting the same real case against the live portal today)
- Single-dependent (Grigsby) — passed cleanly
- Fresh never-touched case (Lease, 2 deps) — didn't even reach this file; failed earlier on "EE already exists on carrier portal" (unrelated pre-existing business/data state)

None of the residual failures reproduce the `parentid='capture'` pattern — fix considered complete for the reported symptom.

**Out of scope / flagged in the PR, not fixed**:
- `EnterSubscriberCoverage.xaml` "Cannot find the policy" — plan-name mismatch on the coverage autocomplete (portal shows a different plan name than SFDC data expects) — data/environment issue.
- `EnterSubscriberInformation.xaml` / `CheckIfThereAreDependents.xaml` still have a few leftover `parentid='capture'` selectors, same risk class, not confirmed broken by current logs.
- `g:RetryCurrentTransaction` (Gusto_Benefits library) throws `KeyNotFoundException` on `LogMessage_ApplicationException` when `MaxContinuousRetryNumber` is hit — confirmed systemic: no process in the repo defines this config key, so this breaks the retry-logging path for every process using this activity. Not project-specific, would need a library-level fix/ticket.

Was not found in the "RPA BenOps Nov 2025" tracking sheet as of investigation — Status/Dev Start Date needs manual add.
