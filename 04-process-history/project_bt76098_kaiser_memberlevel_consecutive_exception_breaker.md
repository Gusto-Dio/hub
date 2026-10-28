---
name: project_bt76098_kaiser_memberlevel_consecutive_exception_breaker
description: BT-76098 Kaiser_GroupSubmissions_MemberLevel_Modern consecutive-failure breaker fix - closed
metadata:
  node_type: memory
  type: project
  originSessionId: becbd106-6151-4758-b228-ea8dfdaf6fbf
  modified: 2026-09-28T23:47:22.876Z
---

TICKET FECHADO ✅ (2026-09-28). Reporter: Bri Boyer. Spike in "Group not in carrier portal" failures (28/17 in two weeks, -15% Kaiser TA rate MTD).

**Root cause**: `ConsecutiveProcessingSystemExceptions` only incremented on `System.Exception` and reset to 0 whenever `SystemException Is Nothing` — also true after every `BusinessRuleException`. Real failures alternated between an `ApplicationException` (BT-75733 fallback-nav) and `BusinessRuleException` ("Group not in carrier portal"), so the counter never reached `MaxConsecutiveProcessingExceptions` (3) and the job silently burned through the whole daily queue instead of faulting.

**Fix**: added `TransactionFailed` flag set on both exception types; reset condition changed to `SystemException Is Nothing AndAlso Not TransactionFailed`. Doesn't reclassify "Group not in carrier portal" itself (declined ask from BT-68870) — only stops the cascading mass-failure pattern.

**PR #3382** merged 2026-09-28T23:01:28Z. Deploy confirmed: package `1.6.6` published to feed AND Process `ProcessVersion 1.6.6` active in Production (Benefits folder, `LastModificationTime 23:09:02Z`) — see [[feedback_buildkite_production_deploy_only_feed_not_process]].

**Validation**: replayed 2 real previously-Failed Production transactions as Staging test items; both hit `NotInAutomationException` (order aged out of automation queue) — itself a `BusinessRuleException`, so it exercised the modified catch cleanly. Never got a live 3-consecutive-failure run to confirm the fault fires at exactly 3 (blocked on fresh queue data at the time), but the logic was verified and deploy is live.

User posted the closing comment on the Jira ticket themselves (2026-09-28) and closed it — see [[feedback_jira_closing_comment_simple_nontechnical]] for the tone/style that worked for this kind of comment.
