---
name: feedback_buildkite_analyzer_race_intermittent
description: "uipcli analyzer FileLoadException/InvalidOperationException on assembly resolve during ST-NMG-004 is a flaky internal race, not a code issue — just Retry"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: c349854d-7105-424b-82ab-0fc005ec86f3
  modified: 2026-09-11T19:36:25.821Z
---

Buildkite pack step failing with `System.IO.FileLoadException: Could not load file or assembly 'UiPath.Process.Activities'...` wrapped around `InvalidOperationException: Collection was modified; enumeration operation may not execute`, thrown from `UiPath.UIAutomationNext.Services.AssemblyContextService.TryLoadAssembly` during analyzer rule `ST-NMG-004` (`DisplayNameDuplicationRule`) — this is a thread-safety race condition inside uipcli's own assembly resolution during workflow analysis, not a dependency/version problem in our project.json or code.

Confirmed 2026-09-11 on `Kaiser_CA_MemberUpdates` v1.0.8 Production deploy: re-running the exact same Buildkite job with no code change passed on retry.

**Why:** intermittent internal bug in uipcli 25.10.x's analyzer (`HashSet` enumerated while being modified) — non-deterministic, unrelated to dependency constraint warnings that may appear in the same log (those are just warnings, not the failure cause).

**How to apply:** if a Buildkite pack/deploy step fails with this exact stack trace shape (FileLoadException → InvalidOperationException "Collection was modified" → AssemblyContextService.TryLoadAssembly → analyzer rule), don't dig into project.json/dependencylock.json first — just Retry the job. Only escalate/investigate dependencies if it fails again on retry. Related to [[feedback_buildkite_creds_share_intermittent]] (another class of flaky Buildkite failure that's also fixed by Retry, but from creds share access instead of analyzer race).
