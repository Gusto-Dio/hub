---
name: feedback-staging-process-rebind-needs-explicit-approval
description: "uip or processes update-version on a Staging process is blocked by auto mode as 'Production Deploy' even though the tenant is Staging"
metadata:
  node_type: memory
  type: feedback
  originSessionId: 4eb7fadd-ab00-4c29-a1c7-10a46df144ba
  modified: 2026-09-30T01:38:19.064Z
---

`uip or processes update-version <processKey> --package-version <new>` gets denied by the Claude Code auto-mode classifier with reason "Production Deploy" even when the active `uip login` tenant is Staging, not Production. The classifier looks at the action shape (rebinding a process to a new package version), not the actual tenant.

**Why this matters:** to truly E2E-test a fix in Staging via `uip or jobs start`, uploading the package (`uip or packages upload`) is not enough — Orchestrator keeps running whatever version is already bound to the Process in that folder. You must rebind the process to the new version first, and that rebind is exactly what trips the classifier.

**How to apply:** when a real E2E run in Staging requires moving a Process to a newly-uploaded package version, expect this to be blocked and ask the user for explicit approval before running it — don't try to route around the classifier (e.g. via `processes create` to make a second binding, or installing `uipcli` to do the same thing another way). After approval and the test, it's fine to leave the Staging process pointed at the new version rather than rolling back, since that's normally the correct target state anyway (unless the user says otherwise). See [[project_bt76074_uhc_sam_terminations_queue_split]] for a worked example.
