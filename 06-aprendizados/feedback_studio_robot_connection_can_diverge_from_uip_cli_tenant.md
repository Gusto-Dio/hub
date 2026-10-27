---
name: feedback_studio_robot_connection_can_diverge_from_uip_cli_tenant
description: "Studio Desktop's robot/Orchestrator connection is independent of the uip CLI's active tenant — Studio can be running debug jobs against Production while uip is set to Staging"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 2c102f09-6385-4925-8797-457e591735e4
  modified: 2026-09-22T01:09:26.615Z
---

Studio Desktop's own Robot/Orchestrator connection (used for `debug start` / attended runs) is a completely separate auth context from the `uip` CLI session. Switching `uip login tenant set Staging` does NOT change what tenant Studio itself is pointed at.

**Why this matters:** during BT-75885 testing, `uip` was set to Staging the whole time, but Studio was still connected to Production — several "Staging test" debug runs actually pulled and processed real Production queue items (visible only by cross-checking the run's `organizationUnitId` in the log: Production's folder was `46023`, Staging's was `48382`) and burned real transactions/SFDC updates on real employee cases.

**How to catch it:** always check the `organizationUnitId` field in the job's own execution logs against the known folder id for the target tenant, don't just trust that the CLI session is on the right tenant. If a debug run's `ReferenceID`/`transactionId` doesn't match a queue item you just created in the tenant you think you're testing in, that's the tell — go check which tenant Studio is actually connected to and have the user switch it there directly (Studio's own login/robot settings, not the CLI).

**How to apply:** before trusting a "Staging validation" run, verify `organizationUnitId` in the log matches Staging's folder id, or confirm the transaction/reference ids match items you added via `uip` in that tenant. See [[project_bt75885_uhc_samx_nhe_modern_type_of_dependent_selector]] for the incident this came from.
