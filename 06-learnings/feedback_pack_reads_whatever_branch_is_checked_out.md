---
name: feedback_pack_reads_whatever_branch_is_checked_out
description: uip rpa pack/build reads files from whatever branch is currently checked out repo-wide, not from the branch where you committed the library change you meant to pack — packing while on the wrong branch silently produces an old/wrong version
metadata:
  type: feedback
  originSessionId: fc2006b8-97b4-4993-82c5-23e7ef1bc824
  modified: 2026-09-10T22:39:33.778Z
---

Git has one working directory shared across all branches. When juggling multiple parallel branches for a multi-library/multi-process fix (e.g. BT-75495's library-branch + several process-branches), `uip rpa pack`/`build`/`validate` always operate on whatever files are on disk **right now** — i.e. whatever branch happens to be checked out repo-wide — not the branch where you last committed the change you intended to pack.

**Concrete miss:** committed a new `SwitchToDelegatedAccount.xaml` + version bump (1.2.1→1.2.2) on library branch `BT-75495-Kaiser-Library-Standalone-DelegateAccount-fix`, then switched to the consuming process's branch (based on `develop`) to wire it in. Ran `uip rpa pack` on the library folder from THAT branch, still expecting the new content — it happily packed version **1.2.1** (develop's version, no new file at all), because checking out the process branch reverted every file in the repo, including the library files, back to `develop`'s state. The pack command gave no warning that it was packing stale content.

**How to apply:** before packing/publishing a library version to test a downstream consumer, run `git branch --show-current` and confirm it matches the branch that actually has the intended commit. If work is split across a library branch + process branch(es) (per [[project_bt75495_kaiser_delegate_account_login]]'s branch-per-library/branch-per-process convention), the sequence must be: checkout library branch → pack → upload → checkout process branch (stash first if it has uncommitted changes) → validate/build against the newly published version. Never assume the currently-open editor tab or the file you just wrote reflects what's on disk after a branch switch — re-verify with `git log --oneline -1` or check the file content directly if in doubt.
