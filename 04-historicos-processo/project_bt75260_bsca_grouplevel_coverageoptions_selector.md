---
name: project_bt75260_bsca_grouplevel_coverageoptions_selector
description: "BT-75260 BSCA_GroupSubmissions_GroupLevel — clone of BT-74292, opened 2026-08-27. Checkbox toggle fixed via ui:Check (not the Click_23 selector fix, which alone was insufficient); live debug 2026-09-01 confirmed it reaches the exception-group page, but hit a NEW downstream stale-selector bug in FillConfirmationForm.xaml ('Reason for submitting'). User wants more testing 2026-09-02."
metadata: 
  node_type: memory
  type: project
  originSessionId: 10b9adc2-2cca-409f-a3aa-47e7496ea432
  modified: 2026-09-01T23:47:15.932Z
---

**Ticket:** BT-75260, reporter Bri Boyer, priority Low, status In Progress (as of 2026-09-01), assigned to me. Clones [[project_bt74292_bsca_grouplevel_plan_modifications]] (BT-74292, Done). Process: `BSCA_GroupSubmissions_GroupLevel`, path `Processes/Benefits/CarrierAutomations/GroupSubmission/BSCA/BSCA_GroupSubmissions_GroupLevel`.

**Branch:** `BT-75260-BSCA-GroupSubmissions-GroupLevel-coverageoptions-selector`, created off `origin/develop` on 2026-09-01. No commits yet.

**No Orchestrator queue** — runs on Schedule, pulls `Carrier_Order__c` via live SOQL (`Queries\SalesforceCarrierOrderQuery.soql`, filters: `Carrier_Information_Name__c = 'Blue Shield of California'`, `Implementation_Stage__c = 'Ready for Submission Prep'`, `Owner.Name IN ('Automation Queue','RPA Automation')`, not 'New Plan', not 'Same Carrier, NO Plan/Group Level Changes'). `ProcessLayer/GetSetTransactionData.xaml` just picks `io_dt_TransactionData.Rows(in_TransactionNumber-1)` in order — reproducing = run `Main.xaml` in Studio debug directly, it naturally picks up whatever's live in the queue; to force a specific known-affected `Carrier_Order__c` Id, could temporarily (local-only, never commit) add `AND Id = '<id>'` to the .soql file.

**Original hypothesized root cause (from Prod log analysis alone, NOT the actual bug — see below):** `ProcessLayer\ReviewPlanChanges.xaml`, `FindChildren_1 "Find Children 'Current Plans'"` (~line 519 pre-edit) throws `SelectorNotFoundException` on selector `<html app='chrome.exe' title='coverageoptions' /><webctrl tag='UL' class='slds-listbox slds-listbox_vertical' />`. Confirmed 3x in Prod logs (2026-08-15, 08-21, 08-26) via closest-match analysis (79%, different class `slds-list_vertical` + `slds-hide`). This was the working theory before live reproduction — may still be a real secondary issue, not yet re-verified against live DOM.

**2026-09-01 — REAL bug reproduced live in Studio debug, different from (and likely upstream of) the FindChildren hypothesis:** User ran `Main.xaml` in Studio debug (no queue seeding, picked up a real live case). Observed: `Click_23` ("Click 'Cancel a product'") executes without throwing, but visibly does nothing on the portal page. The next activity (`TypeInto_2`, "Type Into last day field") expects a date field that only appears after the checkbox is actually toggled — so downstream steps proceed on a page that was never actually updated, consistent with the ticket's "bot doesn't appear to be moving forward... Error message is just 'Error on carrier portal', screenshot shows no visible error."

**Root cause CONFIRMED via two independent sources (both gathered 2026-09-01), do NOT need further live inspection:**
1. **Saved DOM** (`\\gustocloud.apporto\dfs\GSTO\Users\diogenesribei_gsto\Desktop\coverageoptions.html`, grepped for "Cancel a product"): real structure is
   ```html
   <label class="nds-checkbox__label" for="input181-2008">
     <span class="nds-checkbox_faux"></span>
     <span class="nds-form-element__label nds-form-element__control-help nds-checkbox-span">Cancel a product or cancel plans within your existing product</span>
   </label>
   ```
2. **Live-recorded selector** — user added a temporary `uix:NApplicationCard`/`uix:NClick` (modern activity, "Indicate on screen") directly above the broken `Click_23` in `ReviewPlanChanges.xaml` to capture the real live target. It resolved to:
   ```
   <webctrl class='nds-checkbox_faux' tag='SPAN' parentclass='nds-checkbox__label' idx='2' />
   ```

Both agree: the actual clickable toggle is `<span class="nds-checkbox_faux">`, which genuinely still exists in the DOM (no drift for this element specifically). The bug is that the **existing coded selector for `Click_23` never specified this class**:
```
<html app='chrome.exe' title='coverageoptions' /><webctrl tag='C-GROUP-MAINTENANCE-EDIT-GROUP-DETAIL-SCREEN-ENGLISH' /><webctrl aaname='Cancel a product or cancel plans within your existing product' tag='SPAN' /><nav up='1' /><webctrl tag='SPAN' />
```
— the final `<webctrl tag='SPAN' />` has no class, and the `<label>` has 2 SPAN children (the real `nds-checkbox_faux` toggle + the text label span this selector originally anchored from). Without the class constraint it likely resolves to the wrong/ambiguous SPAN, so the click lands somewhere non-functional. The sibling checkbox "Click 'Add a new product'" (`Click_22`) already has the correct pattern and works fine:
```
...aaname='Add a new product or new plans to your existing products.' tag='SPAN' /><nav up='1' /><webctrl class='nds-checkbox_faux' tag='SPAN' />
```

**Fix APPLIED 2026-09-01:** `uipath-rpa` skill loaded fine in the new session (unblocked, plugin update took effect). In `ReviewPlanChanges.xaml`:
1. Added `class='nds-checkbox_faux'` to the final segment of `Click_23`'s selector, matching `Click_22`'s pattern exactly.
2. Removed the temporary `uix:NApplicationCard`/`uix:NClick` scaffolding block (lines 462-495, deleted via `sed` line-range since the block's embedded icon `IconBase64` was too long/error-prone to retype for an `Edit` string match) that had been inserted above `Click_23` for live-selector capture — file is back to only classic `ui:Click`/`ui:TypeInto` activities.

**Verification:** `uip rpa validate --file-path ReviewPlanChanges.xaml` → clean (0 diagnostics). Project-level `uip rpa build` still fails, but only on the pre-existing `UI-DBP-006`/`ST-SEC-008` analyzer errors already documented in this process's `.claude/rules/project-context.md` (confirmed via `git stash` on a prior ticket that these fire identically on the unmodified baseline — same pattern as BT-74147). Not introduced by this fix.

**Still open / next steps:** no build/run smoke test yet (project-level build always fails here regardless of changes — same as BT-74292/BT-74147 precedent, `run` via Studio debug is the real verification path). Need to: run in Studio debug against a live/seeded case to confirm the checkbox actually toggles now and the date field appears, then get into Staging, then open PR (no Orchestrator queue for this process — Studio F5 debug is how to test, per this memory's earlier notes). The original `ReviewPlanChanges.xaml` FindChildren 'Current Plans' selector hypothesis (different class `slds-list_vertical`+`slds-hide`) has NOT been re-verified against live DOM — only the Click_23 root cause was confirmed and fixed; if FindChildren still throws after this fix, that's a separate follow-up.

**2026-09-01 — Click_23 selector fix ALONE was NOT enough.** User re-tested and reported "o click nao funcionou" — same silent no-op as before, even with `class='nds-checkbox_faux'` added. User then manually added (in Studio, outside this session) a `ui:Check` activity right after `Click_23`:
```xml
<ui:Check Action="Check" DisplayName="Check 'LABEL'" sap2010:WorkflowViewState.IdRef="Check_1">
  <ui:Check.Target>
    <ui:Target Selector="&lt;html app='chrome.exe' title='coverageoptions' /&gt;&lt;webctrl sfl-path='siteforceBaseApp/siteforceGeneratedpage*/cGroupMaintenanceEditGroupDetailScreenEnglish' tag='C-GROUP-MAINTENANCE-EDIT-GROUP-DETAIL-SCREEN-ENGLISH' /&gt;&lt;webctrl class='nds-checkbox__label' tag='LABEL' parentclass='nds-checkbox' visibleinnertext='*Cancel a product or cancel plans within your existing product*' /&gt;">
```
i.e. targets the `<label>` itself (not the decorative `<span class="nds-checkbox_faux">`) using UiPath's dedicated checkbox-state activity instead of a generic mouse `Click`. **This is what actually worked** — reported "eu coloquei um checkbox e foi". `Click_23` is still in the file, now structurally correct but functionally redundant/dead (runs, does nothing harmful, superseded by `Check_1` immediately after it). Decision on removing `Click_23` vs. leaving both is still OPEN — asked the user, no answer yet, do not decide unilaterally.

**2026-09-01 03:19-03:27 — live debug run confirms the checkbox now genuinely toggles.** Full `Main.xaml` run against real case `a0mR700000H9iw7IAB` (jobId `5b8957fe-db53-4732-ba19-56b8d2b48d43`): login → GetSetTransactionData (4 cases found) → ProcessTransaction → CheckCaseData → SearchForGroup → ReviewPlanChanges (03:21:44) → TakeFullPageScreenshot → FinalizeProcess → FillConfirmationForm. Inside FillConfirmationForm the page-state polling log shows `excGroup` flipping from `False` to `True` ("Page state: confirm=False excGroup=True excEnroll=False" at 03:25:55) — i.e. the portal actually navigated to the "exception group" review page, something that could never have happened while the checkbox click was a no-op. **This is strong indirect confirmation the Check_1 fix works.**

**NEW bug surfaced downstream (previously unreachable, so never noticed):** once on that exception-group page, `FillConfirmationForm.xaml`'s `TypeInto "Type Into 'Reason for submitting'"` (inside `If "If the exception review page was returned"`) fails with `SelectorNotFoundException`:
```
[2] <webctrl tag='INPUT' type='text' aaname='Reason for submitting this exception request*' />
```
closest live match (67%): `aaname='Reason for submitting this request*'` — the coded selector's `aaname` text has an extra "exception" that isn't in the live DOM's accessible name. This is a plain stale-selector text mismatch, same species of bug as the original Click_23 issue, just in a different file/element, in the local forked `ProcessLayer/FillConfirmationForm.xaml` (the BT-74292 fork, not the shared `Gusto_Benefits` library version — safe to edit here per project rules). Transaction ended `automationStatus=Failed`, `automationMessage="Group Level Changes Failed"` for case `a0mR700000H9iw7IAB`; screenshot saved to `\\fs3-prd-aws.gustocorp.com\BizTech\ExceptionScreenshots\e0493aaf-0d84-47ad-95c3-7e0640e1929b.png`.

**User's read on this run: "passou" (it passed) — wants to test more tomorrow (2026-09-02).** So the Check_1 checkbox fix is considered validated for now. Not yet decided/fixed: (a) the new `FillConfirmationForm.xaml` "Reason for submitting" selector text mismatch, (b) whether to remove the now-dead `Click_23`, (c) the original FindChildren_1 'Current Plans' hypothesis, still unverified against live DOM. **Next session: ask what further testing showed before touching any code — do not preemptively "fix" the Reason-for-submitting selector or remove Click_23 without checking in first, since the user may have already looked at it or may want to scope it as a separate ticket.**

**2026-09-01 (later same day) — session continuity issue + status.** New session started on the WRONG branch (`BT-75274-...`, current work at the time) with the BT-75260 uncommitted diff still sitting in the working tree (never committed/stashed at end of prior session — turned out prior session HAD stashed it as `stash@{1} "WIP on BT-75260-..."`, but a separate uncommitted copy was also present in the tree simultaneously — exact mechanism unclear, worth double-checking `git stash list` for a stale duplicate before any stash pop). Fixed by stashing the unrelated BT-75274 Main.xaml change and `git checkout` into `BT-75260-BSCA-GroupSubmissions-GroupLevel-coverageoptions-selector` — confirmed twice (first checkout appeared to silently revert to BT-75274 between tool calls, second attempt in one combined command stuck). **Lesson: after checkout, re-verify `git branch --show-current` in the SAME tool call as follow-up work, don't trust a prior call's "Switched to branch" message alone.**

User then ran it again and reported **"ta rodando be­m" (running well)** — no further detail on whether the `FillConfirmationForm.xaml` "Reason for submitting" selector bug recurred or was avoided/fixed. User did not act on that fix in this session (no edits made to `FillConfirmationForm.xaml` yet — still just the Click_23/Check_1 fix in `ReviewPlanChanges.xaml` + related files). **User explicitly chose to move to PR prep now** without addressing that known open issue — treat as an intentional scoping call (maybe leaving it for a follow-up ticket), not an oversight; don't block PR prep on it, but flag it in the PR description as a known follow-up if it wasn't actually hit/fixed.

**Status: preparing to open PR** (as of this note). Still uncommitted, nothing pushed yet. Standard pre-PR steps still pending: `/analyze`, dependencylock.json vs develop diff check, projectVersion bump in project.json, `git fetch origin develop` + Buildkite two-dot diff check, commit, PR via `mcp__githubgusto__create_pull_request` (gh CLI not installed on this VDI, see [[feedback_gh_cli_not_installed]]).

**2026-09-01 ~20:43-20:54 — "ta rodando bem" confirmed by full log, 2 cases processed, jobId `01bd25e6-bd4d-43e3-a7ed-569a7049061f`:**
- Case `a0mR700000HWV5NIAX`: reached `ReviewPlanChanges`/`TakeFullPageScreenshot`, then threw `BusinessRuleException "RequirementPlease acknowledge"` — a portal-side requirement/warning banner correctly caught and surfaced; ended `automationStatus=Failed`, `automationMessage="Group Level Changes Failed"`. Looks like intended behavior (flagging for manual review), not a new bug — not yet 100% confirmed, but nothing in the trace suggests a selector/code defect.
- Case `a0mR700000HKHhGIAX`: went through `UpdateContribution → FinalizeProcess → FillConfirmationForm`, `excGroup` stayed `False` throughout (the "Reason for submitting" exception-group path from the earlier bug was NOT hit this run), submit retried ~5x over ~90s ("Page state: confirm=False..." repeating, then "Submit not found during click — page may be transitioning") before `confirm=True` and finishing. Ended `automationStatus=Submitted`, `automationMessage="Group Level Changes Submitted"` — **first fully successful end-to-end transaction with the Check_1 fix.**

Net: checkbox fix (`Check_1`) validated by a real Submitted transaction. The `FillConfirmationForm.xaml` "Reason for submitting" bug is still unaddressed but wasn't triggered in this run (needs `excGroup=True` to hit that code path) — still an open follow-up, not blocking this PR by the user's own call.

**PR OPENED ✅ — #3279** (https://github.com/Gusto/biztech-uipath-rpa/pull/3279), created 2026-09-01T21:05, base `develop`. Title: "[BT-75260] BSCA GroupLevel — fix silent no-op on cancel-product checkbox". Body documents the `Click_23`+`Check_1` fix, `project.json` bump (`Gusto_Benefits` → 1.558.0, projectVersion 5.1.2), and explicitly calls out the `FillConfirmationForm.xaml` "Reason for submitting" issue as a non-blocking follow-up.

**TICKET CLOSED ✅ (2026-09-01T23:37).** PR #3279 approved and **merged** into `develop` (merged_by Gusto-Dio, 1 commit, +34/-23, 2 files: `ReviewPlanChanges.xaml` + `project.json`). Jira BT-75260 status → **Done**, resolution **Resolved**. Ticket fully concluded — no further action needed on the checkbox fix itself.

**Known open follow-up (NOT a separate ticket yet):** `FillConfirmationForm.xaml` "Reason for submitting" stale-selector text mismatch (`aaname` has extra "exception" not present in live DOM) — only surfaces on the exception-group path (`excGroup=True`), wasn't hit in final testing runs, intentionally left out of this PR per user's scoping call. Revisit if it recurs in Prod.
