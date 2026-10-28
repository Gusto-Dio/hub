---
name: feedback-gsuite-readrange-not-cancel-safe
description: GSuite ReadRange cannot be wrapped in Pick/Parallel/scope TimeoutMS to fail fast; cancelling it throws an uncatchable exception
metadata:
  node_type: memory
  type: feedback
  originSessionId: 5a2daf1e-b5eb-4b13-ae44-3218441f6067
  modified: 2026-10-08T02:11:34.593Z
---

Do not try to add a timeout to a UiPath GSuite `ReadRange` by cancelling it (Pick against a Delay, Parallel, or `TimeoutMS` on GSuiteApplicationScope).

**Why:** `TimeoutMS` on the scope had no effect (reads still took ~100 s). A Pick cancelled the read at 30 s but the activity then threw "The activity 'X' threw or propagated an exception while being canceled", which TryCatch/RetryScope did not catch, so there was no retry and the carrier failed (BT-76508, 2026-10-08).

**How to apply:** if fail-fast is needed, use a call with its own cancel-safe timeout (e.g. HTTP Request) instead; and the same GSuite "MarkCanceled" message hides the real error (inner exception is none), so diagnose with timing and direct REST calls rather than the activity's exception.
