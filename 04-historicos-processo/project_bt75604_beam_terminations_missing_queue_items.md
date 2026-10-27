---
name: project_bt75604_beam_terminations_missing_queue_items
description: "BT-75604 - TICKET CLOSED by user 2026-09-11. Not a bug: Tammy confirmed MF_Automation_Date__c business-rule timing explained the queue delay. One real bug survives outside this ticket: Failed case 500R7000016m3XaIAI ('Can't terminate employee') in Beam_Terminations, still unfixed, repro ready in Staging."
metadata: 
  node_type: memory
  type: project
  originSessionId: 821718c2-41cd-40c7-ad1b-1667d98d4021
  modified: 2026-09-11T22:57:07.536Z
---

Ticket BT-75604 (reporter Tammy Borders, assignee Diogenes): 3 Beam_Terminations Salesforce Case Ids —
`500R700001614nJIAQ`, `500R7000016m3XaIAI`, `500R7000017hP6fIAE` — are open/eligible for automation 7+
days but never surface in the UiPath queue, even though `MemberSubmissions_QueueBuilder` runs Successful
every day (verified: last 15 Prod job runs 2026-08-28→2026-09-11, zero faults, zero skipped-queue log
entries).

**Why:** Investigation (Iron Rule followed: logs pulled before code) ruled out a bot crash or code
regression. Git history on `Beam_Terminations.soql` and the QueueBuilder process shows no logic change —
only a mechanical folder move and two unrelated PRs (file-server asset paths #3230, SLO comment #3197).

**Root cause (mechanism, confirmed by reading code):** `ProcessLayer/ProcessTransaction.xaml` mirrors the
Orchestrator queue 1:1 off the SOQL result (`GetSalesForceRecords` → `dtCases`): a case is added only if
it's a row in `dtCases` (line ~406), and an existing "New" queue item whose Case Id is NOT in `dtCases` gets
auto-deleted (line ~335, "Remove Queue Items That Are Not In Query"). So the 3 cases are failing one of
`Beam_Terminations.soql`'s WHERE conditions on the Salesforce side — not a UiPath defect:
```
Automation_Status__c NOT IN ('Failed','Completed','Submitted','On Hold') AND
Type = 'Termination' AND Carrier_Id__c = '64' AND
Status NOT IN ('Solved','Closed','Resolved','Cancelled','On Hold') AND
Owner.Name IN ('MF Automation') AND
Integration_Id__c != NULL AND MF_Automation_Date__c != NULL
```
Leading suspects: `Owner.Name` not yet reassigned to "MF Automation", or `Integration_Id__c` /
`MF_Automation_Date__c` left null on the case.

**How to apply / current state (as of 2026-09-11):**
- Branch `BT-75604-Beam-Terminations-debug-missing-cases` created off `develop` for this investigation.
- Sheets tracking (` RPA BenOps Nov 2025`): BT-75604 **not found** — status/Dev Start Date not updated, needs manual entry.
- Tried an isolated read-only debug harness (`ProcessLayer/DebugQueryOnly.xaml` calling only
  `GetSalesForceRecords`, no queue mutation) to avoid touching Production queues — blocked locally by the
  known `GetRobotCredential` "Error code: 1101 / A folder is required" issue (see
  [[feedback_local_debug_folder_binding]]). Abandoned and cleaned up (file deleted, no trace in git status).
- **Current approach (user's call):** debug the REAL `ProcessTransaction.xaml` in Studio Desktop
  (interactive, run by the user — not headless CLI, so the credential-resolution blocker doesn't apply).
  `Queries/Beam_Terminations.soql` is **currently temporarily modified** (uncommitted) to
  `SELECT ... Automation_Status__c, Type, Carrier_Id__c, Status, Owner.Name, Integration_Id__c FROM Case
  WHERE Id IN ('500R700001614nJIAQ','500R7000016m3XaIAI','500R7000017hP6fIAE')` — i.e. all WHERE gating
  removed, diagnostic fields added, so the query returns these 3 cases regardless of eligibility and lets
  us read their real field values.
  - Breakpoint instructed: the "Retry Scope" activity wrapping "Get SalesForce Records" in
    `ProcessTransaction.xaml` (right after "Initialize transaction values", right before the "Remove Queue
    Items That Are Not In Query" sequence). Step Over (F10) once → `dtCases` populated, zero queue mutation
    yet → inspect → then STOP debug (do not continue) so the Add/Remove queue logic never runs against the
    loosened query.
  - Recommended to debug `ProcessTransaction.xaml` directly (not via `Main.xaml`) with
    `in_TransactionItem` = full path to `Beam_Terminations.soql`, `in_Config` = Dictionary with
    `Credential_SalesforceUser`/`Credential_SalesforceInstance`/`Credential_SalesforceKey` (value = key
    name), to skip looping through every other carrier.
- No PR opened yet. No code fix identified yet — this may turn out to be a Salesforce-side data/ownership-
  routing gap rather than anything fixable in the bot.

## PIVOT 2026-09-11 ~20:15 — QueueBuilder theory WRONG. All 3 cases ARE in the queue; 1 real failure found

Checked the actual Production Orchestrator queue (`Beam_Terminations`, folder `Benefits`) directly via
`uip or queue-items list` instead of continuing to debug the QueueBuilder gate. All 3 case Ids from the
ticket are present, queued and processed **today** (2026-09-11, ~13:20-13:24 UTC — NOT 7+ days ago as the
ticket claimed, meaning the QueueBuilder eventually did pick them up, whatever the original delay was):

- `500R7000017hP6fIAE` (Id 2660938993) — **Successful**
- `500R700001614nJIAQ` (Id 2660938774) — **Successful**
- `500R7000016m3XaIAI` (Id 2660938836) — **Failed**, `ProcessingException`: `{"Reason":"Can't terminate employee","Details":"Failed","Type":"BusinessException"}`, group `WA01172`, retry 0

So the QueueBuilder gate/SOQL investigation (everything above this section) is very likely a dead end for
*this* recurrence — the cases were not permanently stuck out of the queue, they were just delayed, and the
actual bug (if any) is inside the real `Beam_Terminations` carrier automation process
(`Processes/Benefits/CarrierAutomations/MemberSubmission/Beam/Beam_Terminations/`), specifically whatever
throws the generic `BusinessRuleException("Can't terminate employee")` — need to find that throw site (likely
`ProcessLayer/CancelCoverage.xaml` or `CheckTerminationCaseData.xaml`) and get the real underlying reason
(the "Details":"Failed" is uninformative, probably wrapping a more specific inner exception that's being
swallowed).

**Replicated for Staging debug (done 2026-09-11 ~20:17):** added the Failed item's exact `SpecificContent`
(Id, TerminationDate, GroupNumber, CaseData, Subject, BenefitOrderEffectiveDate — same keys/casing as
production, confirmed against `ProcessTransaction.xaml`'s `SpecificContent("GroupNumber")`/`("TerminationDate")`
usage, so no re-pascalization risk here) as a **New** item in the Staging `Beam_Terminations` queue (folder
`Benefits`): Id `2663673448`, Reference `500R7000016m3XaIAI-BT75604-repro`. Scratch JSON temp file (contained
real PII — SSNs, addresses, emails) deleted immediately after.

**Next: debug the real process, not QueueBuilder.** Open
`Processes/Benefits/CarrierAutomations/MemberSubmission/Beam/Beam_Terminations/project.json` in Studio, run
`Main.xaml` in debug against the **Staging** Orchestrator queue item above (`500R7000016m3XaIAI-BT75604-repro`),
and find exactly where/why `CancelCoverage.xaml`/`CheckTerminationCaseData.xaml` throws "Can't terminate
employee" for this case. The 2 Successful cases don't need repro — they already completed fine in Prod.

**Still pending regardless of the above pivot:** revert `Beam_Terminations.soql` in the QueueBuilder project
(step 4 below) before any commit/PR on this branch — it's currently hardcoded to the 3 ticket case Ids and
must not ship, even though the investigation has moved to the carrier-automation process instead.

## Jira comment posted 2026-09-11 — waiting on Tammy before any code action

User's explicit call: give Tammy a status update BEFORE touching any code, since the "not entering the
queue" framing turned out to be wrong (see pivot above). Posted on BT-75604 (by the user directly, English):
summarized that all 3 cases did enter the queue today (2 Successful, 1 Failed — "Can't terminate employee"),
explained the 7-condition SOQL gate in plain terms (see Camada 1/2 analysis above), and asked Tammy to
confirm whether the gate criteria (`Owner.Name='MF Automation'`, `Integration_Id__c`/`MF_Automation_Date__c`
populated) is still correct, or if something changed Salesforce-side in how/when those fields get set.

**Also posted to Slack 2026-09-11** (user sent directly, https://gustohq.slack.com/archives/C0ANAPHL1NE/p1789159786597559): looped in Oscar and Hari with the same summary (Tammy's report, what we found — 3 cases entered the queue today, 2 Successful/1 Failed — and what we already asked Tammy on the ticket), asking if either of them has seen this pattern before or knows of a recent change to how `Owner`/`Integration_Id__c`/`MF_Automation_Date__c` get populated on these cases.

**Slack replies received 2026-09-11 ~17:58-17:59** (same channel/thread as above):
- **Hari:** "no not that I am aware of and have not encountered such scenario previously" — no history of this pattern.
- **Oscar (2 messages):** "It could be a symptom of a failure in some queue builder, not necessarily in that bot." and "It's always been the case that they have it available but it doesn't reach us. There's a lag of a few days on our end, honestly, I've never investigated what causes it."

**Key takeaway:** Oscar confirms this few-day lag between a case becoming available and it reaching our queue is a **known, recurring, never-root-caused pattern** — not a new regression. This lines up with what we found (the SOQL gate conditions on the Salesforce side taking days to be satisfied). Hari has no visibility into it.

**User replied to both on Slack (2026-09-11 ~18:06-18:10):** to Hari, "Understood Hari, thanks for sharing. I will keep an eye on it to understand it better"; to Oscar, "Thanks, Oscar, that's really helpful. For now I'll wait for Tammy to confirm on her side, then we can decide whether it's worth digging into that delay separately. I want to confirm whether there's a new validation we need to incorporate or not, let's wait for Tammy's answer." Both got ✅ reactions.

## TICKET CLOSED 2026-09-11 ~18:35 — user posted closing comment on Jira and closed it as owner

Comment posted (English): confirmed Tammy's business-rule-timing explanation for the 3 cases, noted the
1 real Failed case ("Can't terminate employee") is being looked into separately. User then transitioned
BT-75604 to closed themselves. **This ticket is done — do not reopen or re-investigate the "queue delay"
angle.** If the "Can't terminate employee" failure needs a Jira trail later, it'll need its own ticket
(not reopening this one) — nothing opened for it yet as of closure.

## RESOLVED 2026-09-11 ~18:30 — Tammy confirmed root cause: not a bug, her own business rule timing

Tammy replied on Slack (DM, https://gustohq.slack.com/archives/D0BQBM50NTS/p1789162216691779): *"That
matches what we have also. I think I figured out the issue. These were all future terms and we can't
process those until they are within 15 days of the MF Coverage End Date, so the MF Automation Date was
just added yesterday, but the bot hadn't picked them up yet because they became eligible after the Queue
Builder ran. I flagged this too soon and didn't realize they were all terminations for later in the
month."*

Confirms exactly the gate mechanism mapped above: `MF_Automation_Date__c` is populated by a business rule
(15-days-before-`MF Coverage End Date`) she owns, not by us. It was set on these 3 cases on 2026-09-10, one
day before the `QueueBuilder`'s next run — pure timing, no code fix needed on the "not entering the queue"
side. **This closes that half of BT-75604.** The only real remaining item is the genuine Failed case
(`500R7000016m3XaIAI`, "Can't terminate employee") — still needs debugging in the actual `Beam_Terminations`
carrier process (Staging repro ready, see above).

**Also DM'd Tammy directly on Slack 2026-09-11** (user sent), more direct/consultative version of the Jira comment: confirmed the 3 cases entered the queue, 2 Successful/1 Failed (fixing separately), restated the eligibility fields (Type, Carrier_Id__c, Automation_Status__c, Owner.Name="MF Automation", Integration_Id__c, MF_Automation_Date__c), and explicitly asked her (a) if that still matches how things should work on her end and (b) whether there's maybe another field we're not considering today that should be part of the check — open invitation for her to spot a gate condition we're missing, not just confirm the existing one. Mentioned Oscar's "recurring, never root-caused" comment as context for why this is worth her input.

**Current state:** waiting on Tammy's reply (Jira comment + Slack DM, same questions either way). Do not implement or ship any fix (including the
`Beam_Terminations.soql` revert) as a "resolution" commit until she responds — the only code work still
independently justified regardless of her answer is debugging the real "Can't terminate employee"
`BusinessException` in the Beam_Terminations carrier process (Staging repro item ready: queue `Beam_Terminations`,
folder `Benefits`, reference `500R7000016m3XaIAI-BT75604-repro`, Id `2663673448`) — that failure is real and
unrelated to whatever Tammy says about the gate criteria.

**PENDING — next steps in order, pick up from here (superseded by the pivot above for the queue-not-populated angle, kept for reference):**
1. User runs the Studio Desktop debug session described above (breakpoint on the "Retry Scope" wrapping
   "Get SalesForce Records" in `ProcessTransaction.xaml`, Step Over once, inspect `dtCases`, then STOP —
   never let it continue into the queue Add/Remove logic).
2. User reports back the actual field values (`Automation_Status__c`, `Type`, `Carrier_Id__c`, `Status`,
   `Owner.Name`, `Integration_Id__c`, `MF_Automation_Date__c`) for the 3 cases.
3. Compare those values against each WHERE condition in the original query (§ Root cause above) to pinpoint
   exactly which condition excludes them.
4. **MANDATORY before any commit/PR/further git action:** revert the temporary edit —
   `git checkout -- Processes/Benefits/CarrierAutomations/MemberSubmission/QueueBuilder/Queries/Beam_Terminations.soql`
   (run from repo root) — it is currently sitting modified/uncommitted on branch
   `BT-75604-Beam-Terminations-debug-missing-cases` purely for this live debug session and must NOT ship.
5. Decide the actual fix based on step 3's finding: if it's a Salesforce ownership/field-population gap,
   this is a hand-off to whoever owns that SFDC routing workflow (not a UiPath code change) — update the
   Jira ticket accordingly rather than opening a PR. Only touch `Beam_Terminations.soql` for real if the
   finding shows the query itself is wrong (unlikely given all other carrier queries share the same
   pattern).
6. Update the tracking spreadsheet manually (BT-75604 was not found there — see § above) once a direction
   is confirmed.
