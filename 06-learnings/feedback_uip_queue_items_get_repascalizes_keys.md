---
name: feedback_uip_queue_items_get_repascalizes_keys
description: uip or queue-items get returns SpecificContent with PascalCase key names even when the real stored/expected format is camelCase — always cross-check against the process's JSON Schema file before replicating a Prod item to Staging
metadata:
  type: feedback
  originSessionId: fc2006b8-97b4-4993-82c5-23e7ef1bc824
  modified: 2026-09-11T00:29:03.949Z
---

`uip or queue-items get <key> --output-filter "SpecificContent"` re-serializes the SpecificContent dictionary with **PascalCase** key names (e.g. `CarrierOrderID`, `CompanyName`) regardless of what casing the workflow actually expects or what's really stored. When replicating a real Prod queue item into Staging for testing (BT-75495, `Kaiser_GroupSubmissions_NewPlan`), copying the CLI's output verbatim produced a queue item with `CarrierOrderID` (capital C) while `ProcessLayer\ProcessTransaction.xaml` does a case-sensitive `in_TransactionItem.SpecificContent("carrierOrderID")` lookup (lowercase c) — threw `InvalidOperationException: Can not assign ... to 'carrierOrderID'` immediately on the first transaction.

**Second, related gotcha:** Orchestrator's queue-item `SpecificContent` only accepts flat primitive values — `uip or queue-items add --specific-content` rejects nested objects/arrays with `HTTP 400: Property values must be simple ... not complex or composite data types`. Nested structures (`benefitsAdmin`, `policies` in this case) must stay as JSON-encoded **strings** within the flat dict — which is how the original Prod item actually had them; only the top-level key casing was wrong, not the nesting-as-string convention.

**How to apply:** Before adding a replicated/test item to any queue via `--specific-content`:
1. Find the process's JSON Schema file (usually `JSON Schema/*.json` in the process folder, or search for the exact field name reported in the error, e.g. `grep -ri "carrierOrderID"` across the process) — it's the authoritative source for expected key names and casing, more reliable than either the CLI's fetch output or guessing.
2. Rebuild the payload with those exact camelCase (or whatever the schema says) key names, keeping any nested object/array field as a compact JSON-encoded **string** value (not a real nested object) — Orchestrator's flat SpecificContent model requires this.
3. If a "Can not assign ... to 'X'" error appears on the very first transaction after adding a replicated item, suspect key-casing mismatch first — cheap to verify via the schema file, don't reach for library/dependency causes.

Related: [[feedback_staging_queue_items]] (a different, Salesforce-suffix casing gotcha on a different process — same root lesson: never trust the CLI's default casing for replicated queue payloads, always verify against the real expected format first).
