---
name: project_bt74292_bsca_grouplevel_plan_modifications
description: "BT-74292 BSCA_GroupSubmissions_GroupLevel — bot stuck on 'Group plan modifications' page; NOT closed yet (2026-08-24) despite 2 weeks of Prod logs showing no recurrence, because Bri flagged 2 real stuck orders mid-session. Tested both live: neither reproduced the original bug. Found real root cause of why they weren't picked up: 60-day lookahead window on Effective_Date__c. Surfaced 2 unrelated issues instead (Salesforce Apex class permission error; known 'No changes were made' issue). Branch -v2 cut from develop 2026-08-19, merged current develop 2026-08-24, no code fix yet."
metadata: 
  node_type: memory
  type: project
  originSessionId: ead6d013-b01d-4e2a-8c81-462c1d24e0f4
  modified: 2026-08-24T22:29:51.691Z
---

**Ticket:** BT-74292 — reporter Bri Boyer, priority Low, status In Progress (assigned to me). Reported: bot doesn't move forward after navigating to 'Group plan modifications' page (`BSCA_GroupSubmissions_GroupLevel`), most same/change orders failing with generic "Error on carrier portal" and a blank-looking screenshot. Examples: Carrier_Order__c `a0mR700000FUs7FIAT`, `a0mR700000FlB94IAF`, `a0mR700000FizNKIAZ`.

**Branch:** `BT-74292-BSCA-GroupSubmissions-GroupLevel-plan-modifications-fix-v2`, cut fresh from `origin/develop` 2026-08-19 (includes Ahsen's #3006 NavigateToOnlineRenewals fix and SLO rules PR #3069). Old branch (`...fix`, commit `aae37f574d6`) abandoned, left alone but not the base for new work.

## Root causes found (via Orchestrator prod logs + live Studio debug on 2026-07-28, still referenced for context)

This process has **no Orchestrator queue** — it pulls Carrier_Order__c records live via SOQL (`Queries\SalesforceCarrierOrderQuery.soql`: `Carrier_Information_Name__c='Blue Shield of California'`, `Implementation_Stage__c='Ready for Submission Prep'`, `Owner.Name IN ('Automation Queue','RPA Automation')`, `Submitted_Completed_Datetime__c=null`, `Automation_Message__c != 'Group Level Changes Submitted'`, `Effective_date__c <= NEXT_N_DAYS:60`, `RecordType.Name != 'New Plan'`, `Order_Type__c != 'Same Carrier, NO Plan/Group Level Changes'`).

1. **`ProcessLayer\ReviewPlanChanges.xaml:521`** — `FindChildren_1` "Find Children 'Current Plans'" selector fails on cases that go through a plan-change path (not exercised on 2026-08-19's test case, which was a contribution-only change — flow went straight `SearchForGroup → UpdateContribution`, never touched `ReviewPlanChanges.xaml`). Still unconfirmed whether this reproduces today.

2. **`Libraries\Gusto_Benefits\BSCA\Generic\FillConfirmationForm.xaml`** (shared Library, also used by MemberLevel/Terminations) — checkbox selector `data-omni-key='Checkbox_Declaration'` was seen broken on 2026-07-28 with `SelectorNotFoundException`, closest matches `ValidateCheckbox_AddCancel` (56%), `IP_CheckForUWExceptions` (56%), etc.

3. **"No changes were made as part of this transaction" dialog** — confirmed via saved HTML on 2026-07-29 as a real, distinct error state (`data-omni-key='MSG_NoChangesErrorMsg'` on the error-styled span), separate from the harmless per-section "no changes were made" divs. Previously only seen on a case that had already been submitted earlier in the same debug session (reprocessing confound) — open question was whether it also happens on a genuinely fresh case.

## 2026-08-19 live debug session — first real test on -v2 branch

Ran Studio debug (F5) on the fresh `-v2` branch (still only cosmetic Studio re-serialization diff on `ProcessTransaction.xaml`, no real code changes yet). Picked up case **`a0mR700000GyAPwIAN`** from `GetOpenFulfillmentCases` — a genuinely fresh, never-before-touched case (not the previously-burned `a0mR700000GOx2YIAT`).

**Attempt 1** (transactionId `0f9c48b8`, retriesLeft 1): flow went `SearchForGroup → UpdateContribution → FinalizeProcess → TakeFullPageScreenshot → FillConfirmationForm`. Entered `RetryScope — Click 'Submit'` (`FillConfirmationForm v1.545.0`), clicked Submit, then looped checking `Page state: confirm=False excGroup=False excEnroll=False` **5 times over ~90s** without the page ever transitioning, until the RetryScope timed out and threw. **Live-observed on screen by the user: this was the "No changes were made" block** — the record appeared to have already been modified by someone/something else right before the robot reached it. This is the first time this dialog was confirmed on a genuinely fresh case, not a reprocessing artifact — **root cause #3 (open question from 2026-07-29) is now more likely a real, distinct bug**, though the "someone else modified it first" angle is a new wrinkle not yet explained (possible concurrent manual edit, or a different automation touching the same group).

**Attempt 2** (transactionId `4241d3b1`, retriesLeft 0, final): transaction was retried from scratch (re-did `SearchForGroup`/`UpdateContribution`/`FinalizeProcess`/`TakeFullPageScreenshot`), but this time failed **earlier**, at `Click 'confirmation' acknowledgment`, with `SelectorNotFoundException` on `data-omni-key='Checkbox_Declaration'` — same closest-match candidates as 2026-07-28. Salesforce was written back: `automationStatus=Failed`, `automationMessage="Group Level Changes Failed"` (not "...Submitted", so this case likely remains SOQL-eligible for reprocessing in principle).

**After this run, the test item became unavailable in the queue again** — could not reproduce further or continue investigating in this session. Matches the recurring "queue builder" blocker documented on 2026-07-29 (no known process in this repo populates `Implementation_Stage__c='Ready for Submission Prep')`, mechanism is external to this repo, likely Salesforce-native Flow/Apex).

**Unrelated infra warning seen in the same run:** `Take screenshot failed with error: The user name or password is incorrect. : '\\usscl1-fs-3\BizTech\ExceptionScreenshots'` — network share credential issue, not related to the BSCA bug itself, not yet reported separately.

**Posted Jira comment (2026-08-19, id `4383426`):** "Tested against a fresh case today and saw the 'No changes were made' block on the carrier portal — as if the record had already been modified by someone/something else right before the robot reached it. We're now waiting on a new test item to reproduce the issue further." User is moving the ticket to **On Hold / waiting on reporter for a new test item**.

## Next steps when a new item becomes available

1. Confirm whether the "No changes were made" block reproduces again on a fresh item (now 1-for-1 observed live, but cause of the underlying "already modified" state still unexplained).
2. Get live UI Explorer selector fix for `data-omni-key='Checkbox_Declaration'` in `FillConfirmationForm.xaml` (still broken, confirmed again 2026-08-19).
3. Root cause #1 (`FindChildren 'Current Plans'`) still unconfirmed for today's Library/portal version — need a case that actually goes through a plan-change path (not just contribution-only).
4. Identify the "queue builder" mechanism (still unknown, likely Salesforce-native) so test items don't disappear before they can be fully investigated.

## 2026-08-24 session — branch synced, Prod logs checked, Bri escalation tested live, ticket NOT closed

**Branch sync:** switched to `-v2` branch (56 commits behind `develop`), merged `origin/develop` cleanly
(no conflicts, no changes to this process's folder in that gap — only an unrelated Anthem library
file). Confirmed `git -c http.sslBackend=openssl fetch` needed (see
[[feedback_git_tls_schannel_fix]]) — plain `git fetch` failed with a full TLS handshake failure to
github.com specifically (google.com worked fine) until the user re-authenticated Cloudflare WARP.

**First debug run (job `4e1bdd05-...`, 2026-08-24 21:06):** ran clean end-to-end (login,
`NavigateToOnlineRenewals`, SOQL query) but `transactionCount: 0` — no case matched the standard
eligibility query at that moment. Expected/known blocker (see "queue builder" note above).

**Prod log check (was about to close the ticket):** pulled last ~14 days of Orchestrator jobs for
`BSCA_GroupSubmissions_GroupLevel` (`uip orchestrator jobs list --all-folders --process-name
"BSCA_GroupSubmissions_GroupLevel"` — note `--folder-path`/`--folder-key` flags exist but
`--all-folders` avoided needing to guess the right folder, see
[[reference_orchestrator_folder_vs_repo_path]]). Confirmed the **original reported bug (silently
stuck on "Group plan modifications", generic "Error on carrier portal", blank screenshot) has NOT
recurred in 14 days of daily scheduled runs.** Did find 2 unrelated `Faulted` jobs (2026-08-15,
2026-08-21), both with the identical error — `SelectorNotFoundException` on `<webctrl tag='UL'
class='slds-listbox slds-listbox_vertical' />` on the `coverageoptions` page — a **distinct,
different bug** from this ticket, not yet filed separately. User decided (2026-08-24): close
BT-74292 now, keep monitoring, and if `coverageoptions` recurs tomorrow, open a **new** ticket for
it then (not now, not preemptively).

**Mid-close escalation from Bri Boyer (Slack, ~2h before this session's close attempt):** flagged 2
specific same/change orders "in queue" about to time out to the manual team —
`a0mR700000GrYX0IAN` (group `W0113908`) and `a0mR700000GnDPWIA3` (group `W0130592`). This paused
the close — these are exactly the kind of real test cases the ticket had been blocked waiting for.

**Diagnostic technique used (repeatable for future "why isn't this case being picked up" questions):**
`GetSalesForceRecords_1` in `ProcessLayer/GetSetTransactionData.xaml` (~line 222) reads the SOQL
text live via `File.ReadAllText("Queries\SalesforceCarrierOrderQuery.soql")` — so the query file can
be edited as **plain text** (not XAML, no rebuild, no debug protocol needed) to add `WHERE Id IN
(...)` and inspect real field values by breakpointing on the **next** activity after it (`If_6` "If
Transaction Data Exists", not on `GetSalesForceRecords_1` itself — a breakpoint pauses *before* an
activity runs, so breakpointing the query activity itself would show stale/empty data). Always
revert the `.soql` file to its committed state immediately after reading the diagnostic result —
confirmed via `git diff --stat` showing zero diff each time before proceeding to the next step.

**Root cause of why Bri's 2 cases weren't in the automation's queue — confirmed via this technique:**
both records pass every eligibility filter in `SalesforceCarrierOrderQuery.soql` EXCEPT
`Effective_date__c <= NEXT_N_DAYS:60`. Both have `Effective_Date__c = 2026-11-01`; today
(2026-08-24) + 60 days = 2026-10-23 — 9 days short. **This is a lookahead-window miss, not a bug.**
Both have `Submission_Deadline_Date__c = 2026-12-01`, so per this window logic they become eligible
around 2026-09-02, well ahead of deadline — assuming no separate Salesforce-side "time in queue" SLA
is independently aging them toward manual regardless of the automation's 60-day window (open
question, asked Bri directly).

**Live validation run against both real cases (user's idea, confirmed as a real Prod transaction —
not a simulation, no Dev/QA environment exists for this process):** re-applied the same `Id IN
(...)` diagnostic query (this time letting the query actually feed `Main.xaml`'s full run, not just
a read-only inspection) specifically to test whether these 2 cases — which are `Order_Type__c =
'Same carrier, plan/group level changes'`, i.e. a genuine plan-change path — would reproduce the
original "Group plan modifications" stuck bug. **Neither did:**
- `a0mR700000GrYX0IAN`: hit a **new, distinct** error — a Salesforce Apex class permission popup on
  the portal: *"Looks like you don't have access to EEA_UpdateSubGroupRating Apex class. Your
  Salesforce admin can help with that."* This is a portal/Salesforce access-config issue (the
  automation's portal login lacks permission to an Apex class the "plan modifications" flow now
  depends on) — not a bug in this repo's code, needs a Salesforce admin to grant access.
- `a0mR700000GnDPWIA3`: hit **"No changes were made"** on save — this is the SAME known issue
  already documented above (§ "2026-08-19 live debug session", root cause #3), not a new bug, and
  still not the original ticket's symptom.

**Conclusion communicated to Bri (2026-08-24, Slack — message sent by the user):** explained the
60-day window as the real reason neither case had been attempted yet, that testing both directly did
NOT reproduce the original "stuck on Group plan modifications" bug, flagged the new
`EEA_UpdateSubGroupRating` Apex permission error as a separate Salesforce-side issue to resolve with
her Salesforce admin, and asked her directly whether a separate SLA timer exists in Salesforce that
would pull these out of automation before the 60-day window opens naturally (~2026-09-02) — this
answer determines whether widening the query's lookahead window is actually necessary, which should
NOT be done unilaterally without understanding why 60 days was chosen (likely to avoid submitting to
the carrier portal before plan/rate data is finalized — changing it risks trading "picked up late"
for "rejected by the portal for being premature").

**Ticket status: still NOT closed** — waiting on Bri's answer about the separate SLA timer before
deciding whether BT-74292 (or a new ticket for the Apex permission error / `coverageoptions` bug)
needs further action. Branch `-v2` has zero code changes still (only the develop merge) — nothing to
revert or worry about there.
