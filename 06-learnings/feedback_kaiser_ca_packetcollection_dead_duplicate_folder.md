---
name: feedback_kaiser_ca_packetcollection_dead_duplicate_folder
description: Processes/Benefits/CarrierAutomations/Advising/Packet_Collection/Kaiser_CA/ is a dead/orphaned duplicate of Kaiser/ (same projectId, no Orchestrator package binding anywhere) -- the ticket's "Advising_Kaiser_PacketCollection" is the Kaiser/ folder (no _CA), already migrated to Windows months ago
metadata:
  type: feedback
  originSessionId: <this-session>
  modified: 2026-09-10T23:08:10.202Z
---

Two repo folders exist for what looks like "the same" Kaiser packet-collection bot, and they share the exact same `projectId` (`df075128-1ada-450c-a632-9f06fc3518a1`) in `project.json` — but only one is real:

- `Processes/Benefits/CarrierAutomations/Advising/Packet_Collection/Kaiser/` (no "_CA") — `"name": "Advising_Kaiser_PacketCollection"`, already `targetFramework: "Windows"`, `Gusto_Benefits 1.555.1`, `projectVersion 1.11.14` on `develop`. **This is the live one** — published to Staging Orchestrator as package+process `Advising_Kaiser_PacketCollection`, currently at v1.11.11 (Windows, published 2026-06-12 by harinath.reddy), bound and active in the `Benefits` folder.
- `Processes/Benefits/CarrierAutomations/Advising/Packet_Collection/Kaiser_CA/` — `"name": "Advising_Kaiser_CA_PacketCollection"`, was still `targetFramework: "Legacy"`, `Gusto_Benefits 1.530.7`. **This is a dead/orphaned duplicate** — its package (`Advising_Kaiser_CA_PacketCollection`) exists in the Staging package feed (last published 2025-12-17 by oscar.nunez) but has **zero process bindings** in any Orchestrator folder, tenant-wide. Nobody runs it.

**How this bit me on BT-75495:** the Jira ticket lists the impacted process as `Advising_Kaiser_PacketCollection` (no "_CA") — exactly matching the real, live folder. I went looking by carrier+state naming convention ("Kaiser CA" = Kaiser Permanente California, matches the ticket's carrier scope) and picked the `Kaiser_CA` folder by name-plausibility alone, without cross-checking against the ticket's exact process name or an Orchestrator lookup first. Spent significant work doing a full Legacy→Windows migration + delegate-switch wiring in the dead folder, only caught when `uip or processes create` failed with `HTTP 409: name already used` — which surfaced the real, already-Windows, already-live process under the "no _CA" name.

**How to apply:** before touching ANY process folder for a ticket, when a ticket names a process (e.g. from Jira, from Tammy/Bri/etc's list), grep/search the Orchestrator tenant for a process or package with that EXACT name first (`uip or processes list --all-folders` / `uip or packages versions <name>`), not just find a repo folder that looks like a plausible match by carrier/state naming. If a repo folder's `project.json` "name" doesn't exactly match the ticket's process name string, stop and verify — don't assume a state-suffix (`_CA`, `_TX`, etc.) is just a naming variant of the same thing. Same root lesson as [[feedback_verify_process_guid_before_editing_sibling]] (SAM vs SAMx), but this time two folders shared an identical `projectId` too, which made it look even more like "the same project, just an old path" — that assumption still has to be verified against what's actually deployed, not inferred from the repo alone.
