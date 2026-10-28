---
name: feedback_scope_identifier_mismatch
description: "Diagnostic pattern for \"Check succeeds but Click/TypeInto right after fails with NodeNotFoundException\" in NApplicationCard-based workflows — suspect ScopeIdentifier mismatch, not the selector"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 96d1932d-6c14-438d-8471-79ee758861bf
---

When a `uix:NCheckState`/`ui:UiElementExists` immediately before a `uix:NClick`/`uix:NTypeInto` on the same element family **succeeds** (correctly reports "appeared"/exists), but the click/type activity right after it **fails** with "Could not find the user-interface (UI) element for this action" (`NodeNotFoundException`) — check the `ScopeIdentifier` attribute on the failing activity before suspecting the selector itself.

**Why:** `ScopeIdentifier` tells UiPath which already-attached `NApplicationCard` window/app handle to search within. It's a separate mechanism from the selector — if it points to a `ScopeGuid` that doesn't exist in the current workflow's execution (e.g. it was copy-pasted from an activity in a *different* XAML file that has its own `NApplicationCard` with that GUID), the search has no valid handle and **always** fails, regardless of whether the element is genuinely on screen. This produces a deceptively confusing symptom: the sibling check activity (correctly scoped) proves the element exists, making it look like a flaky-selector or timing issue, when it's actually a structural scope bug.

**How to confirm:** `grep -rn "<the ScopeIdentifier GUID>"` across the whole project. If it only matches a `ScopeGuid=` in a **different** file (not the enclosing `NApplicationCard` in the current file), that's the bug — fix by pointing `ScopeIdentifier` to the correct enclosing `NApplicationCard`'s own `ScopeGuid`.

**When this arises:** most commonly after copy-pasting an activity (e.g. a "Click X" that already worked in another workflow) into a new `NApplicationCard.Body` without updating its `ScopeIdentifier` to the new card's `ScopeGuid`.

Found and fixed in [[project_bt74025_guardian_packetcollection]] (2026-07-05, PR #2892).
