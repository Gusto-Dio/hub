---
name: project_bt75006_oxford_newplan_zipcode_sfdc
description: "BT-75006 Oxford_GroupSubmissions_NewPlan — PR #3213 OPEN, review feedback addressed (2026-08-24). Real root cause of the zip-code-adjacent navigation failure was a Fully Insured/Level Funded toggle timing race in EnterCompanyInfo.xaml (not Zip Code itself) — fixed with DelayBefore/DelayAfter + resilience delays. The generic-exception SFDC-update change was REVERTED per Ahsen's review — skipping SFDC update on non-BRE exceptions is intentional (lets the queue item retry before aging out). PR now scoped to just the toggle-race fix. Awaiting re-review/merge."
metadata: 
  node_type: memory
  type: project
  modified: 2026-08-24T16:39:31.788Z
  originSessionId: 64b75f28-88d6-466c-b81c-27e5ff57cf5f
---

**Ticket:** BT-75006 — reporter Bri Boyer, priority Medium, status In Progress, assigned to Dio. Impacted automation: `Oxford_GroupSubmissions_NewPlan` (repo path: `Processes/Benefits/CarrierAutomations/GroupSubmission/Oxford/Oxford_GroupSubmissions_NewPlan`). Reported issue has two parts: (1) bot types the company zip code but doesn't correctly select the matching dropdown option, causing an error moving to the next page; (2) even when transactions fail in UiPath, the SFDC Carrier_Order__c isn't updated with an automation status/message, delaying manual-team pickup.

**Branch:** `BT-75006-Oxford-GroupSubmissions-NewPlan-zipcode-sfdc-status-fix`, cut fresh from `origin/develop` (2026-08-20/21, commit `3c50301fee7`).

**Context:** Oxford_GroupSubmissions_NewPlan is a near-duplicate of `UHC_GroupSubmission_NewPlan_SAMx` (git history: "modernize as copy of modern UHC SAMx process", BT-72984; later "port pending UHC SAMx portal fixes", BT-74369) — same portal (`uhceservices.com`, `SamxOne SSO` htmlwindowname), separate process folder, fixes are manually ported between the two, not shared via a library. See also [[project_bt75058_uhc_samx_newplan_quote_pdf]] for the sibling process's unrelated Quote-PDF investigation.

## Current understanding — quick summary (end of session, 2026-08-21)

1. **Fix #2 (SFDC not updated on generic failures) — DONE ✅.** `ProcessLayer/ProcessTransaction.xaml`
   generic catch-all `If.Else` (was missing an `UpdateCarrierOrder.xaml` invoke) now has one,
   mirroring the other 3 call sites. Per-file `validate` clean. Project `build` fails on 65
   pre-existing analyzer errors confirmed unrelated (identical count/set on baseline `develop`
   via `git stash` test) — not a real blocker, this project's Buildkite doesn't gate on full
   `uip rpa build` anyway.
2. **Fix #1 (original hypothesis: harden Zip Code selection like SIC Code) — LIKELY A RED
   HERRING, not implemented, probably not needed.** The Prod "Total Applying Employees not
   found" error and the live-reproduced "Click 'Group Details' not found" error both trace to
   the **same actual root cause**, confirmed via live DOM inspection: the "Fully Insured" and
   "Level Funded" funding-type toggles (`EnterCompanyInfo.xaml` `NCheck_3`/`NCheck_4`, mutually
   exclusive) ended up **both checked** — an invalid portal state that silently blocks the
   "Next" button from rendering (no visible error). Working theory: `NCheck_4`
   ("Uncheck Level Funded") fires before the SPA finishes re-rendering after `NCheck_3` ("Check
   Fully Insured") auto-unchecks Level Funded, so `NCheck_4`'s click re-toggles it back on — a
   **timing race, not a Zip Code problem**. User added `DelayBefore` on the `NCheck_4` activity
   itself (not a separate Delay activity) to test this — a re-run with that delay got past
   "Group Details" cleanly (URL progressed start-quote→group-details→owner-information→census)
   confirming the theory, though one clean run isn't 100% proof yet (recommend 1-2 more runs).
   **Not yet ported to a permanent fix** — still deciding between keeping the `DelayBefore`
   (simple, less robust) vs. a state-verified click on the Level Funded toggle before deciding
   whether to click it (more robust, mirrors the SIC Code pattern) — user hasn't chosen yet.
3. **Bonus confirmed-live finding (not this ticket's main scope but real):** `UpdateCarrierOrder.xaml`
   hit `[STRING_TOO_LONG]` writing an untruncated `in_AutomationMessage` to
   `Automation_Message__c` (255-char SFDC field limit) during the same re-run — matches a
   risk flagged in original investigation as "not yet confirmed for Oxford", now confirmed.
   Chatter/FeedItem fallback saved the message, but the record's own field is likely blank.
   Lower priority, not blocking.
4. **Bonus unrelated finding (out of scope, flag only):** the same re-run failed later on a
   legitimate "Dependent Coverage Mismatch" on the Census page — the bot's correction pass
   examined 0 of 2 expected grid rows. Possibly a separate gap in census-correction logic, not
   investigated further.
5. **Local-only, must-revert-before-commit:** `Data/config.json` has `LocksFolderPath` and
   `ExScreenshotsFolderPath` both edited to work around short-hostname DNS failures on this VDI
   (mapped drive `Z:\Locks` / FQDN UNC respectively) — user explicitly said never to commit
   this, revert both before any PR.

**What's actually left to do:** decide + implement the permanent fix for the Fully
Insured/Level Funded toggle race (delay vs. state-verified click), validate/build, revert
`Data/config.json`, then this ticket's two reported symptoms (zip code navigation error +
SFDC not updated) are both addressed.

## COMMITTED ✅ (2026-08-22, commit `3e15135b167`)

User chose the simple `DelayBefore`/`DelayAfter` approach (not state-verified) for the toggle
race, and asked to add delays across all fields on this page for resilience. Before committing:
reverted `Main.xaml` (100% Studio ViewState/reformatting noise, zero functional change — Studio
resaving the file during the debug session bumped every HintSize by fractional pixels) and
reverted `EnterCompanyInfo.xaml` to `HEAD` first, since Studio's live-debug save had reordered
attributes across the *entire* file (6528-line diff, but grepping confirmed the only real
content change was `NCheck_4`'s new `DelayBefore="5" DelayAfter="4"` — everything else was
attribute-order/HintSize noise). Reapplied that one real change by hand plus the additional
delays, keeping the final diff to exactly 8 attribute additions:
- `TypeInto_5` "Zip Code": `DelayBefore="500"`
- `TypeInto_6` "Total Eligible Employees": `DelayBefore="500"`
- `TypeInto_7`/`TypeInto_18`/`TypeInto_19` (Counting Methodology FTE/Eligibles/ATNE):
  `DelayBefore="500"` each
- `NCheck_1` "Check Medical": `DelayBefore="2"` (seconds — confirmed `uix:NCheck` is the modern
  "N"-family activity, distinct unit from classic `TypeInto`'s millisecond `DelayBefore`)
- `NCheck_3` "Check Fully Insured": `DelayBefore="2"`
- `NCheck_4` "Uncheck Level Funded": `DelayBefore="5" DelayAfter="4"` — the exact values the
  user live-tested and confirmed fixed the race (job `28cc4d14-...`, 2026-08-21 22:34-23:01)

Also reverted `Data/config.json` to the original UNC paths before staging (confirmed via
`git status` — clean). Kept `project.json`'s `Gusto_Benefits` bump to `1.557.1` (matches root
`dependencylock.json`, Studio auto-aligned it during the session) — verified before commit that
no other dependency needs bumping: `UiPath.Excel.Activities` has a pre-existing mismatch
(`3.4.1` vs lock's `2.24.4`) but this project's `settings.json` already has
`skipTests: ["update_version","update_dependency"]`, so Buildkite won't check it — not
introduced this session, not blocking. `projectVersion` untouched (`1.55.12`), per the rule to
only bump when explicitly asked. Left `entry-points.json` / `project.uiproj` untracked
(Studio-generated scaffolding, same repo-wide pattern seen on unrelated processes at session
start) — not staged.

Final commit `3e15135b167` on branch `BT-75006-Oxford-GroupSubmissions-NewPlan-zipcode-sfdc-status-fix`
touches exactly 3 files: `ProcessLayer/EnterCompanyInfo.xaml`, `ProcessLayer/ProcessTransaction.xaml`,
`project.json`. Both `validate` (per-file) and `build` (project-level, 65 pre-existing analyzer
errors, unrelated) were clean/expected before commit.

## PR OPENED ✅ (2026-08-22) — https://github.com/Gusto/biztech-uipath-rpa/pull/3213

User decided not to run additional Staging transactions before opening the PR (one confirmed
debug run was enough for them). Before pushing: merged `origin/develop` into the branch (it was
several commits behind — `git diff origin/develop..HEAD --name-only` was showing ~46 unrelated
files per the Buildkite two-dot-diff gotcha) and re-verified the diff was clean afterward (exact
same 3 files, same content) before push + PR. PR body documents the pivot from "Zip Code
selection" to "Fully Insured/Level Funded toggle race" as the real root cause, the one
confirmed debug run, and flags (not fixes) the Census mismatch gap and the `STRING_TOO_LONG`
risk as out-of-scope follow-ups.

**Ticket is essentially done pending PR review/merge.** Nothing else pending unless review
comes back with requested changes, or the user decides to run more Staging confirmation after
all.

## Investigation (via `benops-ticket-investigation` skill)

- **Phase 0 (Sheets):** ticket NOT found in the tracking spreadsheet (`RPA BenOps Nov 2025`) — highest ticket there is BT-72959. `_sheets_not_found = true`, status/Dev Start Date not updated there.
- **Phase 1 (Orchestrator Prod logs, Benefits folder 46023):** sampled 5 recent faulted jobs (08-15 through 08-20). Dominant, consistent error across all 5 (multiple retries per job):
  ```
  Could not find the UI element corresponding to this selector:
  <webctrl tag='INPUT' type='text' aaname='Total Applying Employees' />
  closest matches include 'Zip Code' (75%) and 'SIC Code' (75%)
  at EnterCompanyInfo.xaml → Sequence "Enter Group Details" → TypeInto "Total Applying Employees"
  ```
  3/5 sampled jobs also hit unrelated login/account-locked failures in the same window (`Login page not available`, `Account is locked`, `Login failed due to invalid credentials`) — infra issue, out of scope for this ticket.
- **Phase 2 (Jira):** only one comment, an auto-bot note saying the ticket was scheduled for review but not picked up. No linked tickets.
- **Phase 3/4 (git/PRs):** recent commits are all Oxford-specific fixes (BT-74369 chain, BBO-3785 SLO rules) — nothing recently touched the Zip Code step or the catch-block SFDC branch. This looks like a long-standing latent bug, not a new regression.

## Root cause #1 — Zip Code dropdown selection (confirmed via code read)

`ProcessLayer/EnterCompanyInfo.xaml`, `TypeInto_5` "Type Into 'Zip Code'" (~line 369): `Text="[in_ZipCode.Substring(0,5)+ "[k(enter)][k(enter)]"]"` — types the zip and blindly presses **Enter twice** to pick the autocomplete dropdown's matching option. Zero verification, zero retry.

The exact same file has `Sequence_SelectSICVerified` ("Select SIC Code with verified exact option", ~line 516) whose annotation explicitly documents this exact failure class and how it was fixed there: *"The Abyss SIC dropdown can load slowly. Do not rely on Enter selecting the highlighted row because stale/unfiltered options can cause a random SIC selection. Type the numeric prefix, wait for the exact 'CODE - ...' option, click that option, then verify the input value and aria-invalid state before proceeding."* — a `While` loop (`While_SelectSICVerified`, 4 attempts) that clears, retypes, waits for the exact option, clicks it, and verifies before proceeding, else throws a clean `BusinessRuleException`.

That same hardening was never applied to Zip Code. When the double-Enter silently mis-selects or fails to select, the page doesn't advance to Group Details, so the next expected field (`Total Applying Employees`) is never found — exactly the Prod error.

**Confirmed identical vulnerable code exists in the sibling `UHC_GroupSubmission_NewPlan_SAMx/ProcessLayer/EnterCompanyInfo.xaml`** (same TypeInto_5, same selector, same double-Enter, no verification) — not reported there yet, but same latent risk. Out of scope for this ticket (separate process folder), flagging for awareness only.

**Blocker on fix #1:** cannot hand-write the dropdown-option selector or the verification-field selector — needs live capture (`uia-configure-target`) against the real Oxford portal, same as the BT-75058 pattern where the user ran a live Studio debug session. Waiting on that before implementing.

## Root cause #2 — SFDC not updated on generic failures (confirmed via code read)

`ProcessLayer/ProcessTransaction.xaml`'s catch block (`TryCatch_4`, inside `If_DebugSkipTxnStatus_1.Then` i.e. only when `NOT debugMode`) classifies the exception via `If_1`:
- `BusinessRuleException` → invokes `UpdateCarrierOrder.xaml` (SFDC gets updated) ✅
- `exception.Message = "Object reference not set..."` → also invokes `UpdateCarrierOrder.xaml` ✅
- **any other exception (the final bare `If.Else`, `SetTransactionStatus_5` "Set status to Failed w/ App error", `ErrorType="Application"`)** → only calls `SetTransactionStatus`, **never invokes `UpdateCarrierOrder.xaml`** ❌

Our Zip Code failure (root cause #1) is a plain `System.Exception` (UI selector not found) — not a `BusinessRuleException` — so it falls exactly into the uncovered branch. This is why SFDC's `Carrier_Order__c` is never touched on these failures, matching the ticket's second complaint exactly.

**Secondary/related risk (not yet confirmed for Oxford specifically, seen in sibling UHC SamX Prod logs during a past investigation):** `Automation_Message__c` in `UpdateCarrierOrder.xaml` (~line 280/349) receives `in_AutomationMessage` with no length truncation (`Automation_Message__c` is a standard SFDC field, likely 255-char limited) — a `[STRING_TOO_LONG]` Salesforce error was observed there for a different exception type in the sibling process. Only `SetTransactionStatus`'s `Reason` gets truncated to 10000 chars; the SFDC field write itself does not. Worth hardening alongside fix #2 but confirm it's actually hit for Oxford before scoping it in.

**Fix #2 is mechanical, no live capture needed:** add the missing `UpdateCarrierOrder.xaml` invoke (same argument pattern already used at the other 3 call sites in this file) inside the generic `If.Else` branch (~line 2838-2854).

## Next steps
1. Get a live debug/capture session on the Oxford portal (same approach as BT-75058) to capture the Zip Code dropdown option selector + a post-selection verification field, then port the SIC-Code-style verified-retry pattern to Zip Code.
2. Implement fix #2 (add the missing `UpdateCarrierOrder.xaml` call) — can be done without live capture, just needs `uip rpa validate`/`build` after.
3. Consider (separately, lower priority) truncating `in_AutomationMessage` before the SFDC write in `UpdateCarrierOrder.xaml`, to avoid a possible `STRING_TOO_LONG` failure masking the fix.
4. Decide whether to also flag the identical Zip Code vulnerability in the sibling `UHC_GroupSubmission_NewPlan_SAMx` process (not part of this ticket, no report yet there).
5. `_sheets_not_found` — update the tracking spreadsheet status manually if/when it gets added there.

**Status as of 2026-08-21 (session 2):** Fix #2 implemented and verified.
- `ProcessLayer/ProcessTransaction.xaml`, catch block's generic `If.Else` (Sequence_123, was
  `If_24.Else` under `If_1.Else` — the "not BusinessRuleException, not Object-reference"
  branch feeding `SetTransactionStatus_5` "Failed w/ App error") now also invokes
  `InvokeWorkflowFile_37` → `UpdateCarrierOrder.xaml` (`in_AutomationStatus="Failed"`), mirroring
  the pattern at the other 3 call sites in the file (same arg list, `in_GroupID` left empty to
  match the `If_21.Then` BusinessRuleException-branch style).
- Per-file `validate`: clean (`No diagnostics found`).
- Project-level `build`: fails with 65 pre-existing analyzer errors (`UI-DBP-006` top-level
  selector, `ST-DBP-002` arg count on `EnterCompanyInfo.xaml`, `ST-SEC-008` SecureString scope)
  — **confirmed pre-existing via `git stash` + rebuild on baseline (develop): also 65 errors,
  identical set, none referencing `ProcessTransaction.xaml` or the new invoke.** Fix #2 itself
  is clean; this project's `build` was already broken before this ticket and isn't a usable
  gate here (Buildkite for this project doesn't appear to run full `uip rpa build` — see
  `settings.json#skipTests` in project.json, only version/dependency checks are enforced).

**Fix #1 (Zip Code) — live confirmation obtained 2026-08-21, capture in progress.** User
debugged live in Studio Desktop and hit exactly the predicted failure point:
`Click_13` "Click 'Group Details'" (`EnterCompanyInfo.xaml` line 735, right before
`TypeInto_TAE` "Total Applying Employees" at line 758) threw `SelectorNotFoundException` on:
```
<webctrl aaname='Group Detailschevron_right' parentid='contentContainer' tag='BUTTON' type='button' />
```
Closest matches (83%→75%: `calendar_today`, `Import Quote`, `arrow_forward`,
`cloud_uploadUpload Template`, `downloadDownload Template`, `arrow_back`, `close` x2, empty x2)
have **zero semantic relation** to "Group Details" — confirms the button is genuinely absent
from the DOM, not a stale/renamed selector. `parentid='contentContainer'` is a generic SPA
shell container reused across many pages, which is why fuzzy matches pull from unrelated
sections (quote import/upload/download) — not a sign the bot is on the wrong page. User
visually confirmed on the live page: button is not there. This is the direct downstream
symptom of root cause #1 — `TypeInto_5` "Zip Code" (line 369, blind `[k(enter)][k(enter)]`,
zero verification) apparently fails to properly select the autocomplete option, so the
current section never validates and the "Group Details" expand button never renders.

**Sequence in `EnterCompanyInfo.xaml` for reference:** Zip Code (369) → Effective Date (381) →
Total Eligible Employees (393) → Counting Methodology switch (405-515) → SIC Code verified
selection `Sequence_SelectSICVerified` (516-693, the hardened pattern to mirror) → Medical/Fully
Insured/Level Funded checkboxes (694-733) → **Click 'Group Details' `Click_13` (735, fails
here)** → Total Applying/Waiving Employees (758+).

**Next step:** need the user to capture, on the live Zip Code autocomplete dropdown, the exact
option element structure (tag/aria-role/innertext pattern) and a post-selection verification
signal (input value + invalid-state attribute, mirroring the SIC Code pattern's `GetAttribute`
calls on `value`/`aria-invalid`) so the verified-retry `While` loop can be ported to Zip Code.

**MAJOR PIVOT (2026-08-21, live DOM inspection) — real root cause may NOT be Zip Code at all.**
User saved the live page HTML (`samx-lf-hcc.uhceservices.com.html`, ~2.7MB, saved to their
Desktop) while stuck at the `Click_13` "Click 'Group Details'" failure. Zip Code and every
other field the user visually checked showed correct values with **zero visible error** —
ruled out a visible-validation-error explanation. Grepping the saved DOM found the actual
cause: the fixed-position footer bar that should contain the "Next"/advance button renders
completely empty (`<div style="width: 120px; height: 40px;"></div>`, no label/icon mounted;
sibling `<div role="alert"></div>` also empty — no error surfaced). Digging into the
Medical/Fully&nbsp;Insured/Level&nbsp;Funded toggle group (`EnterCompanyInfo.xaml` `NCheck_1`/
`NCheck_3`/`NCheck_4`, ~lines 706-720) found:
```html
<input data-testid="fiToggle-abyss-toggle-input-checkbox" type="checkbox" value="FI" ...>  → checked (class ...-checked-true)
<input data-testid="lfToggle-abyss-toggle-input-checkbox" type="checkbox" value="LF" checked="">  → ALSO checked
```
**Both "Fully Insured" and "Level Funded" are checked simultaneously** — almost certainly a
mutually-exclusive funding-type toggle group (radio-like), so this is an invalid/contradictory
state that the portal silently rejects (blocks advance, no visible error message) instead of
throwing a validation error. `NCheck_4` (`Action="Uncheck"`, DisplayName misleadingly says
"Check Level Funded") runs LAST, after `NCheck_3` "Check Fully Insured" — working theory: since
Fully Insured/Level Funded are mutually exclusive, clicking Fully Insured likely
auto-unchecks Level Funded via the portal's own logic; if `NCheck_4` then blindly clicks
Level Funded's label again (misreading a stale "still checked" snapshot, or the SPA state
hadn't finished re-rendering yet — a timing/race condition), it **re-toggles Level Funded back
to checked**, producing the invalid double-checked state seen live.

**User independently reached the same timing-race theory** and set the `DelayBefore` property
directly on the `NCheck_4` activity itself (not a separate `Delay` activity) to test whether
the page/toggle state hadn't finished loading when the Uncheck click fired. Mid-test the portal
session logged out (SSO/session timeout) — re-run needed to confirm. **Not yet confirmed**: whether a Delay alone fixes it (timing race) vs. needing a
state-verified click (check actual `checked` attribute before deciding to click, mirroring the
SIC Code verified-retry pattern) — the more robust fix either way is almost certainly to verify
Level Funded's real DOM state before acting, rather than trust a blind Action="Uncheck".

**Two candidate fixes now on the table for this ticket** (Zip Code fix #1 from original
investigation may turn out to be a red herring, or a secondary issue — need to keep both open
until confirmed): (a) harden Zip Code selection (original hypothesis, not yet live-confirmed
this session), (b) fix the Fully Insured/Level Funded toggle race in `EnterCompanyInfo.xaml`
`NCheck_3`/`NCheck_4` (new hypothesis, strong live DOM evidence, not yet confirmed as the fix
that unblocks the footer button — pending user's re-run after re-login).

**RE-RUN RESULT (2026-08-21 22:34-23:01, job `28cc4d14-...`, after user added a `Delay` before
the Level Funded uncheck step to test the timing-race theory):** the "Click 'Group Details'"
failure **did NOT reproduce**. SIC code selected on attempt 1/4 (no retries needed). Browser
URL progressed cleanly `start-quote` (22:53:24) → `group-details` (22:54:05) →
`owner-information` (22:54:11) → `census` (22:54:24) — confirms "Group Details" is genuinely
the next route/page name, and the delay (or at least this run) got past the toggle-race point
that blocked the footer button previously. **Supports hypothesis (b) — the Fully
Insured/Level Funded toggle timing race — as the real root cause of the original failure**,
though one clean run isn't proof; recommend a couple more runs to rule out flakiness before
committing to a permanent fix (state-verified click, mirroring the SIC Code pattern, is more
robust than a fixed Delay).

**Run failed later on an unrelated, legitimate business scenario:** Census page "Dependent
Coverage Mismatch" (an employee has a dependent not reflected in the selected coverage tier) —
the bot's Coverage-Type auto-correction pass found 0 of 2 expected grid rows to examine and
correctly threw `BusinessRuleException` for manual review. This looks like a separate,
possibly pre-existing gap in the census correction logic (why did it expect 2 rows but examine
0?) — **out of scope for BT-75006** (which is about zip code + SFDC status), flagging only for
awareness, not investigating further unless asked.

**CONFIRMED LIVE: the `[STRING_TOO_LONG]` SFDC risk flagged in the original investigation
(§ Root cause #2, "Secondary/related risk") actually occurred in this run**, not just
hypothetically: `UpdateCarrierOrder.xaml`'s "Update Record - Carrier_Order__c" failed with
`[STRING_TOO_LONG]` (`Automation_Message__c` capped at 255 chars, the census-mismatch message
was ~350+ chars, untruncated). The workflow's fallback (`Insert Record - FeedItem`, i.e. a
Salesforce Chatter post with the full message) succeeded, so `UpdateCarrierOrder` itself still
reported success overall — but the `Carrier_Order__c` record's own `Automation_Message__c`
field almost certainly ended up blank, meaning anyone checking the record field directly (not
the Chatter feed) sees nothing. Worth fixing (truncate `in_AutomationMessage` before the SFDC
write) but this was already noted as lower-priority in the original investigation — not
blocking BT-75006's two main fixes.

**Unrelated local-only change — DO NOT let this reach a commit:** `Data/config.json` has TWO
UNC paths edited for local debugging, both because the configured **short hostname**
(`usscl1-fs-3`, no `.gustocorp.com` suffix) fails DNS resolution on this VDI even though the
Cloudflare-group access fix from 2026-08-17 is in place (FQDN resolves fine) — see
[[feedback_vdi_missing_locks_share_access]] for the full `Test-Path` evidence:
- `LocksFolderPath`: `\\usscl1-fs-3\BizTech\RPA\Locks` → `Z:\Locks` (drive already mapped via
  `net use`, persistent, confirmed `Test-Path` True).
- `ExScreenshotsFolderPath`: `\\usscl1-fs-3\BizTech\ExceptionScreenshots` →
  `\\usscl1-fs-3.gustocorp.com\BizTech\ExceptionScreenshots` (FQDN directly — no drive mapped
  at the `\BizTech` level, so used FQDN instead of mapping a new letter).

Both are needed so the user can run/debug `InitAllApplications.xaml`'s login-lock step AND the
catch block's screenshot-on-error step locally in Studio. **User explicitly asked: revert
`Data/config.json` to the original UNC values before any commit/push/PR** — this file is shared
with Staging/Prod which access the share directly via UNC with no local drive mappings.

**Before wrapping up this ticket:** confirm `git diff` on `Data/config.json` is reverted (both
`LocksFolderPath` and `ExScreenshotsFolderPath` back to the short-hostname UNC originals) —
only `ProcessTransaction.xaml` (fix #2) and whatever fix #1 ends up touching should be in the
final commit. No other UNC/network paths exist in this file (full contents checked 2026-08-21).

## Review feedback + revert (2026-08-24) — PR #3213

Ahsen (`ahsennur`, MEMBER) reviewed with **CHANGES_REQUESTED**:
> "hi, not updating sfdc when a non-BRE (system exception) happens is to give order change to
> retry and hopefully pass before it drops from automation queue."

This means the generic-exception `UpdateCarrierOrder.xaml` invoke added for fix #2
(`InvokeWorkflowFile_37`, the "Set status to Failed w/ App error" branch) was **wrong by
design, not just a bug** — skipping the SFDC update there is intentional so the queue item can
keep retrying instead of being marked Failed prematurely. This also explains the separate
`gusto-fresh-eyes[bot]` finding on the same PR (double CO update if a "Warning in enrollment
page" failure surfaces as a system exception instead of a BRE) — same root cause, not two bugs.

**Action taken:** reverted the `InvokeWorkflowFile_37` block in
`ProcessLayer/ProcessTransaction.xaml`'s generic/system-exception catch branch, restoring
original behavior (only `SetTransactionStatus_5` "Failed w/ App error", no SFDC write).
Verified via `git stash` + rebuild that this branch's pre-existing 65 analyzer errors are
identical before/after (unrelated, confirmed pre-existing on `develop` baseline too). Committed
as `47c8720a2f7` and pushed; replied to Ahsen on the PR (issue comment, since his
CHANGES_REQUESTED had no inline review thread to reply to directly).

**PR #3213 is now scoped to just the Fully Insured/Level Funded toggle-race fix** (the actual
reported navigation error) plus the resilience delays on the Company Info page. The original
"fix #2" (SFDC status on generic failures) is fully reverted — that symptom in the ticket was
apparently either a misdiagnosis or intentionally out of scope; **do not re-attempt it without
first confirming with Ahsen/team what the actual desired behavior is** for non-BRE failures
(possibly: only update SFDC after retries are exhausted, not on every individual attempt — not
yet confirmed, would need to ask before implementing).

**Lesson for future PRs touching this catch block:** the three exception branches
(BusinessRuleException / "Object reference not set" / generic-Application) are NOT
symmetric by oversight — the missing SFDC update on the generic branch is deliberate retry-queue
behavior, not a gap to fill.
