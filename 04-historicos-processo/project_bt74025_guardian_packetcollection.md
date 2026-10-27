---
name: project_bt74025_guardian_packetcollection
description: BT-74025 Advising_Guardian_PacketCollection — root cause fixed (scope mismatch on retry-loop click), PR #2892 open, v1.20.7 live on Staging
metadata: 
  node_type: memory
  type: project
  originSessionId: 62117765-cdd5-4d6a-b11a-0e445566eb30
---

# BT-74025 — Advising_Guardian_PacketCollection failures

**Status (2026-07-02):** Investigation still OPEN. Two root-cause theories proposed and walked back after scrutiny from Diogenes during live Studio debugging. No code fix applied yet. Branch created: `BT-74025-Guardian-PacketCollection-fix-groupid-selector` (name is misleading now — kept as-is).

## Theory 1 (DISPROVEN) — groupId/groupID case typo
`CollectPacket.xaml` lines 430/541 (`TypeInto "Type group number"`) use `id='groupId'`; sibling `UiElementExists` checks (lines 374, 556) use `id='groupID'`. Looked like a case regression from PR #2784.
**Disproven:** a live-saved copy of the actual target page ("Obtain forms and materials - Producer _ Guardian.html") has `id="groupId"` (lowercase) and no `groupID` anywhere. The TypeInto selector is correct. Do NOT apply a groupId→groupID swap.

## Theory 2 (DISPROVEN) — bot ends up on wrong page (Home) due to login/state-detection false negative
Proposed that `InitAllApplications.xaml`'s `homeExist` check false-negatives and misroutes into a bogus re-login, or the loose `groupIdBarExists` selector (`<html app='chrome.exe' /><webctrl id='groupID' />`, no title/tag scoping) passes on some unrelated page.
**Disproven by Diogenes:** the ticket's actual failing error ("Type group number" SelectorNotFoundException) happens *inside* `CollectPacket.xaml`, which is only reached *after* successful login and after `ProcessTransaction.xaml`'s own Home→Renewal-package navigation already logged success (`"Menu home appeard"` → `"Renewal package appeared"` → `"Clicked on Renewal package bottom"`, all Info-level, all succeeded). So the login-detection bug (real, reproduced live separately — see below) is NOT the cause of the original ticket's "Type group number" failures; it's a distinct issue.

## Unresolved oddity worth re-examining
Between `"Clicked on Renewal package bottom"` (14:45:43.971Z) and the `"Type group number"` error (14:50:33.555Z) in job `130fcb4c-3a57-488e-84f8-55c28e293f79`, there is a **~4m50s gap with zero intermediate log lines** (checked all non-Verbose levels). The `TypeInto`'s `Target.TimeoutMS` is explicitly `{x:Null}` (line 431-433) — i.e. it falls back to whatever the project-level default UI Automation timeout is, which is plausibly ~5 minutes given this gap. This means the search for `id='groupId'` was genuinely retried by UiPath's own element-search engine for ~5 minutes straight and never found it — not an instant typo-driven failure. Tried to pull the job's attached failure screenshot via `uip or attachments list --job-key <key>` to see the actual on-screen state at that moment — **returned empty** (screenshots likely saved to local robot disk/network share, not uploaded as an Orchestrator attachment for this process). No visual evidence obtained yet for what page/state was actually on screen during a real automated failure.
**Open question:** why does the live automated run never find `groupId` for ~5 min on a page that manually looks correct? Candidates not yet checked: intermediate popup/overlay covering the field without preventing DOM existence-check *visibility* requirements, a redirect/error page silently substituted, or genuine vendor-side flakiness/A-B page variant.

## Separate, likely-real bug found live (2026-07-02, Diogenes debugging in Studio) — statically analyzed 2026-07-03
In `CollectPacket.xaml`, `InterruptibleDoWhile "Retry Click View until popup opens"` (~line 838-963): the `Click 'view'` activity (line 846, `SimulateClick="True"`, selector `<html app='chrome.exe' title='Obtain forms and materials - Producer | Guardian' /><webctrl aaname='View' />`, line 858) is immediately followed by an **unconditional** `LogMessage "Clicked on view button"` (line 861) — logged regardless of whether the click actually landed. Diogenes observed live: the bot did NOT actually click "View" but the workflow proceeded as if it had.

**Static re-analysis (2026-07-03) — the `popupOpened` detection itself looks correct, the gap is what happens after 3 failed retries:**
- Line 862 `UiElementExists "Wait for popup to open"` independently checks for the new window (`title='Consolidated Renewals App - Google Chrome'`) and assigns `popupOpened` — this is a real, working check, not a rubber stamp.
- The `TryCatch "Try attach to popup browser"` (867-951) re-validates via `NCheckState` (line 881) against a specifically-scoped selector (`ScopeSelectorArgument` requires the popup title) — so even if `NApplicationCard`'s loose `TargetApp` selector (`url='*'`, line 913-915) attaches to the wrong/original Chrome tab, the actual existence check still correctly re-derives `popupOpened` from the right scope.
- Loop condition `Not popupOpened AndAlso clickRetryCount < 3` (line 963) does correctly retry up to 3x when `popupOpened` is False.
- **The real gap:** after the loop exits with `popupOpened` still False (3 failed clicks), there is **no explicit check/throw**. Execution falls through to line 966 `UiElementExists "Wait for PDF viewer Download button"` — its `Exists` output is bound to `{x:Null}` (discarded), so it can't signal failure either. Next is `NApplicationCard "Chrome guardianlife - Sign In"` (line 971, `AttachMode="ByInstance"`, selector `title='Consolidated Renewals App'`) with **no surrounding TryCatch at this level** — if the popup never opened, this attach will throw, but the resulting exception is attributed to this generic attach activity, not to "click view failed 3x", making root-cause from logs alone harder for whoever triages that failure later.
- Likely cause of the silent click failure itself: `SimulateClick="True"` on a JS-driven "View" control — SimulateClick can report success without the page's real event listener firing (same class of issue as [[project_bt73708_bsca_group_member_level]]'s Edit Subscriber fix, which needed `InteractionMode=HardwareEvents` + a JS scrollIntoView instead of relying on simulated clicks).
- **Ruled out:** `clickRetryCount` is a workflow-scoped `Variable` with `Default="0"` (line 263) inside `CollectPacket.xaml`, which is invoked fresh per transaction — no cross-transaction leakage of the retry counter.
- **Important scoping note:** this loop runs only in the *download* phase, strictly after a successful group search (`packageAvailable = True`). It happens **after** the point where the original ticket's `TypeInto "Type group number"` failure occurs, so it is confirmed **not** the root cause of the original ticket's SelectorNotFoundException — it's a separate, independently real bug found while stepping through live.

**Suggested direction (not yet applied — needs live confirmation first per the lesson learned below):** after the `InterruptibleDoWhile` exits, add an explicit `If Not popupOpened Then Throw` (mirroring the pattern already used at line 1041 `If NOT (packageAvailable OR packetNotAvailable)`), and consider swapping `SimulateClick="True"` for a hardware-event click on the "View" control.

**Note (still valid):** "9/1" in the ticket/queue data = 9/1/2026 insurance renewal date cohort (`RenewalDate` field), not a calendar date in July.

## Lesson learned this session
Two root-cause theories built from Orchestrator logs + static XAML reading alone were both wrong, and were only caught because Diogenes cross-checked with (a) a live-saved copy of the real page DOM and (b) his own live Studio debugging session, pushing back on inconsistencies (activity location relative to login, gap timing, click-then-assumed-success). **Do not present a fix as final based on log+code reading alone for this ticket — verify against live behavior first.**

## Next steps (2026-07-03)
1. **Still the main blocker:** get eyes on the actual screen/DOM at the exact moment `TypeInto "Type group number"` fails in a *real* run — this is the missing evidence for the ~5min-timeout oddity. Studio Desktop on this VDI does **not** support `uip rpa` CLI tooling (`uip rpa studio start` fails with "Studio does not support rpa-tool" — checked 2026-07-03), so `focus-activity`-based precise breakpoints are unavailable. Options: (a) Diogenes drives Studio manually with the mouse to set the breakpoint and describes what he sees; (b) a workflow-level (whole-file) headless breakpoint via `uip rpa debug start` as a fallback (pauses at the first activity of the file, not the exact line); (c) trigger a real Staging job via `uip or jobs start` (never `uip rpa run`/`debug start` for this — see [[feedback_orchestrator_job_trigger]], it hijacks the dev's own VDI screen) and inspect logs/attachments after the fact.
2. ~~Investigate the `popupOpened` check logic~~ — DONE (2026-07-03), see analysis above. Confirmed a real but *separate* bug (missing post-loop failure check + likely `SimulateClick` root cause), NOT the cause of the original ticket's `TypeInto` failure — that loop runs later in the flow, after a successful search.
3. Only after concrete live evidence on item 1: decide on and apply an actual fix for the original ticket. The Click-View bug from item 2 can be fixed independently/in parallel once confirmed live, per the lesson learned below.
4. The 2 Staging queue items below are still unused (not yet run) — good for step 1.

## Staging test items added (2026-07-02, queue `Guardian_Packets`, folder `Benefits`)
- Id `2425459293`, ref `BT-74025-TEST-Haddy-valid` — valid group 40366 (Haddy, inc.)
- Id `2425461126`, ref `BT-74025-TEST-InvalidGroup` — invalid group `00000000`, to validate the existing `BusinessRuleException("Invalid group ID: ...")` path once the real bug is found/fixed

## Real production repro item copied to Staging (2026-07-03)
Found the **actual Production transaction that failed** for this ticket (Production job `130fcb4c-3a57-488e-84f8-55c28e293f79` — same job key already referenced above in the "Unresolved oddity" section). Fetched via Orchestrator OData (`GET /odata/QueueItems(2411018666)`, folder `Benefits/CarrierAutomation`, OrganizationUnitId 46023, queue `Guardian_Packets` Id 9421) since `uip or queue-items get` only accepts the GUID key, not the numeric transaction Id from an Orchestrator URL.
- Production failure detail: `Status: Failed`, `ProcessingExceptionType: ApplicationException`, error `"The UI element is invalid. Make sure the target application is open and the element is on the screen."` — this is a UiElement-not-found class error, consistent with (but not proof of) the `TypeInto "Type group number"` SelectorNotFoundException theme from the original ticket.
- Copied as-is into Staging `Guardian_Packets` queue (Id 5892, same folder path, OrganizationUnitId 48382 in Staging) with status **New**, ready for Diogenes to debug:
  - Staging item Id `2428854260`, Key `8cc5c157-7046-4572-bd15-aa7a0eaa82e8`, ref `BT-74025-Emanate-Biomedical-repro`
  - `SpecificContent` (exact field names/casing preserved from Production raw `SpecificData`, per [[feedback_staging_queue_items]]): `group_name: "Emanate Biomedical Inc"`, `carrier_name: "Guardian"`, `carrier_state: "CA"`, `group_number: "90809"`, `sfdc_link: "https://gusto.my.salesforce.com/006R700000jsNEjIAM"`, `packet_label: "Emanate Biomedical Inc_2026-09-01 Guardian Renewal Packet"`, `renewal_date: "9/1/2026"`, `row_index: "134"`, `spreadsheet_ID: "1tzIgFPqN6QZF8bQZjM8XXhthh2zVsEZTsjaP0HfDDk0"` (cobra_type/blocked_date/first_attempt_date/bot_error_message empty, bot_success/bot_error false).
- This is the best lead yet for step 1 of "Next steps" — it's a guaranteed real repro of the exact failure mode, not a synthetic test case.

## Fix committed (2026-07-03), commit `20043742f` on this branch
Diogenes made manual Studio edits and had them committed:
- `CollectPacket.xaml`: added `NCheckState` checks (main search flow + `NApplicationCard` retry branch) that detect the portal's "Based on the criteria entered, no matching form or material has been found" message *before* the `TypeInto "Type group number"` and throw a `BusinessRuleException` instead of letting the search silently hang/timeout. This is a plausible real fix for the ~5min-gap oddity (item probably showed this message and nothing detected it, so the bot kept waiting until the UI Automation default timeout). Also added a log message after `Click 'view'` in the packet-download retry loop (cosmetic, not the click-then-assume-success fix suggested earlier — that's still open).
- `project.json`: bumped `Gusto_Generic_Activities` 1.6.0→2.0.0 and `Gusto_Generic_SalesForce` 1.10.0→2.0.0 — confirmed intentional by Diogenes (2026-07-03), not an accidental Studio auto-update.
- Staging repro item re-added after the fix (item consumed by a prior run): Id `2428921408`, Key `04a1ccee-7bf6-44e2-9582-f5bfad6c11c9`, ref `BT-74025-Emanate-Biomedical-repro`, queue `Guardian_Packets` (Staging), status New — ready for Diogenes to trigger and confirm whether the new NCheckState fix resolves the original failure.
**Status update:** root cause theory now has an applied, committed fix — but still needs a live Staging run to confirm before calling this ticket resolved.

Related: [[uip_rpa_cli_reference]] — tenant-switching gotcha discovered while investigating this ticket.

## Root cause found and fixed (2026-07-04/05) — PR #2892

Diogenes added a new "Renewal package" retry-recovery block to `CollectPacket.xaml`'s main search loop (a `RetryScope` wrapping an `NApplicationCard` that re-checks and, if needed, re-clicks the "Renewal package" link, in case the portal silently bounced back to Home mid-search). Live Staging run on 2026-07-04 hit this immediately:

**Symptom:** `NCheckState "Check App State 'Renewal package'"` reliably logged **"Renewal package appeared"**, but the very next activity — `NClick "Click 'Renewal package'"` — reliably failed with `NodeNotFoundException` ("Could not find the user-interface (UI) element for this action"), every single time, until the RetryScope exhausted all 6 retries and the exception propagated all the way up, failing the whole transaction.

**Root cause:** the `NClick`'s `ScopeIdentifier` was copy-pasted from a *different file* — it pointed to `3f67acc3-0eab-43c9-bd17-f7ffed70993b`, which is the `ScopeGuid` of `NApplicationCard_1` in **`ProcessTransaction.xaml`** (a completely separate workflow/scope), not the `NApplicationCard_4` (`ScopeGuid="8daf330a-ca1a-40bb-8240-2de01630e435"`) that actually wraps this click in `CollectPacket.xaml`. The sibling `NCheckState` in the same block had the correct `ScopeIdentifier` and worked fine — only the `NClick` had the wrong one. Since `ScopeIdentifier` tells UiPath which already-attached window/app handle to search within, pointing to a scope that doesn't exist in the current file's execution guarantees `NodeNotFoundException` regardless of whether the element is actually on screen.

**General lesson (reusable diagnostic pattern):** when a `NCheckState`/`UiElementExists` immediately preceding a `NClick`/`NTypeInto` on the *same element family* succeeds, but the click/type right after it fails with "Could not find the UI element" — suspect a `ScopeIdentifier` mismatch first (especially after copy-pasting an activity from another workflow file), before suspecting the selector itself. `grep` the suspect GUID across the whole project; if it resolves to a `ScopeGuid` in a *different* file, that's the bug.

**Fix applied (commit `a1d82cab6`, PR #2892):**
- `CollectPacket.xaml`: corrected the `NClick`'s `ScopeIdentifier` to match its enclosing `NApplicationCard_4`; added `ContinueOnError="True"` on the `RetryScope` itself (Diogenes's call — this recovery step is a "nice to have", not required, so exhausting retries should let the transaction continue rather than fail outright); added a **second** "no matching form or material has been found" → `BusinessRuleException` check placed *after* submitting the search (the prior PR/commit `20043742f` only checked *before* submitting, in two places — this closes the gap for when the message only appears post-search), mirrored in both the main search loop and the "Invalid group ID" retry branch.
- `UpdateBotError.xaml`: wrapped the GSuite spreadsheet update in `TryCatch` so a Sheets failure doesn't crash bot error handling.
- `project.json`: version bumped 1.20.6 → 1.20.7.
- Also fixed along the way (unrelated to the crash, cosmetic/robustness): an `NApplicationCard` warning ("Applications cannot be opened when using an input element...") on this same `NApplicationCard_4` — caused by `OpenMode` not being explicitly set to `Never` while `InUiElement` (Input) was also set; fixed by adding `OpenMode="Never"` (mirrors the pattern already used on `NApplicationCard_2` elsewhere in this file for pure-attach cases).

**Status:** PR #2892 open against `develop`, v1.20.7 packed/uploaded/activated on Staging (`Advising_Guardian_PacketCollection`, folder `Benefits`, process key `BB8C3B4D-6F2A-468C-BCDC-361ADCEF86FC`). Still pending: a live Staging transaction run to confirm the retry-scope click now actually succeeds end-to-end (not yet re-tested after the fix as of PR creation).

**Buildkite gotcha hit again on this ticket:** `develop` had moved since the branch was created (unrelated Payroll/Kaiser commits landed), so `git diff origin/develop..HEAD --name-only` showed out-of-scope files before merging — confirms [[feedback_language_jira_prs]]-adjacent CLAUDE.md rule is a real, recurring need, not just boilerplate. Always run the Buildkite two-dot diff check right before opening a PR, not just once at branch creation.
