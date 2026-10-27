---
name: feedback_dead_invokeworkflowfile_vs_compiled_activity
description: A same-named local workflow file (ProcessLayer/X.xaml) can be dead code wrapped in CommentOut while a compiled library activity with the same name is what actually runs — diff the WRONG file and you'll miss the real difference between two processes
metadata:
  type: feedback
  originSessionId: fc2006b8-97b4-4993-82c5-23e7ef1bc824
  modified: 2026-09-10T21:44:20.308Z
---

Comparing the same-named local workflow file (e.g. `ProcessLayer/SearchForGroup.xaml`) between two UiPath processes is not proof they run the same logic. In this codebase's migration history, it's common for a process to have BOTH:
- an `ui:InvokeWorkflowFile` call to the local `ProcessLayer/X.xaml` — but wrapped inside a `ui:CommentOut`, i.e. dead code left over from before a library migration
- a compiled library activity with a similar/same display name (e.g. `gkg:SearchForGroup`) that is the one ACTUALLY invoked

Diffing `ProcessLayer/SearchForGroup.xaml` across two processes can show them as byte-identical while one process actually runs a completely different implementation (the compiled `gkg:` activity), because the local file is unused. This produced a wrong "no step is missing" conclusion on BT-75495 — the real difference (a missing `NGoToUrl` pre-navigation step) lived in `Framework/Process.xaml`, the file that decides which of the two (dead local file vs. live compiled activity) actually gets called.

**How to apply:** Before diffing "the same workflow" between two processes to rule out a missing step:
1. Find where each process actually **invokes** that workflow (grep the orchestrating file — usually `Framework/Process.xaml` or similar — for the workflow's name).
2. Check whether that invocation is inside a `ui:CommentOut` (dead) — if so, find what actually executes instead (often a same-purpose compiled library activity, prefixed like `gkg:`).
3. Only diff the code paths that are actually live in both processes. A byte-identical `ProcessLayer/X.xaml` file proves nothing if one side never calls it.
4. Also check the calling context (`Process.xaml`) itself for steps immediately BEFORE the invocation — a missing pre-navigation/setup step there is invisible if you only diff the invoked workflow file.
