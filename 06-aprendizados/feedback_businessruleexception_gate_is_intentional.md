---
name: feedback_businessruleexception_gate_is_intentional
description: "Don't widen a ProcessTransaction.xaml catch-block's exception.GetType.Name=\"BusinessRuleException\" gate on Carrier_Order__c status/Owner updates — it's intentional, not a bug"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 4ee82993-c738-42c1-a940-407626d721a9
  modified: 2026-09-18T16:58:27.293Z
---

In carrier `ProcessTransaction.xaml` catch blocks that call `UpdateCarrierOrder(Failed, ownerId=<manual review queue>)`, a condition gating that call on `exception.GetType.Name="BusinessRuleException"` is **intentional design**, not an oversight — confirmed by Ahsen in PR review (BT-75847, PR #3348).

**Why:** the Owner reassignment is a one-way burn — once it fires, the record is effectively pulled out of automation and can't self-heal ([[feedback_salesforce_owner_burn_guard]]). Restricting it to `BusinessRuleException` (deterministic business-logic failures that won't succeed on retry) lets transient/technical exceptions (selector timeouts, UI glitches, network hiccups) get their retry window (`MaxRetryNumber` in `Data/config.json`) without prematurely burning the record. Widening the gate to "any non-debug exception" makes every technical hiccup burn the Owner on the very first failure, killing the retry's chance to self-heal.

**How to apply:**
- Never remove/widen this exception-type check as a fix for "SFDC status isn't updating on fault" — that symptom is usually the *underlying automation bug* not faulting into a `BusinessRuleException` in the first place (fix the automation bug instead, per [[project_bt75847_uhc_samx_newplan_zip_sfdc_status]] fix #1), or a genuine gap in handling permanently-exhausted retries (see below), not a reason to widen the gate for every attempt.
- If the real gap is "items that exhaust ALL retries and are still stuck with no SFDC update," the correct fix is to gate the update on **last-attempt-only**, not exception type: `ProcessTransaction.xaml` already receives `in_RetryNumber` and `in_Config("MaxRetryNumber")` as arguments (today only used to compute a `wbRetriesLeft` log field) — compare `in_RetryNumber >= CInt(in_Config("MaxRetryNumber"))` to detect the final attempt and fire the update then regardless of exception type, while keeping earlier attempts silent for non-business exceptions. Nobody has actually built this yet — it's a follow-up idea, not implemented.
- Check other carrier processes with the same `ProcessTransaction.xaml` pattern (BCBS_TX confirmed, likely others) for the same intentional gate before "fixing" it there too.

Related: [[feedback_salesforce_owner_burn_guard]], [[project_bt75847_uhc_samx_newplan_zip_sfdc_status]].
