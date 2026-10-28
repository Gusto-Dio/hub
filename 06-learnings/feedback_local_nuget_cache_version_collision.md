---
name: feedback_local_nuget_cache_version_collision
description: "Re-packing the same library version number locally with different content gets shadowed by the stale local NuGet cache; DLLs get locked by the uip rpa background Studio host so you can't just delete it — bump to an unused version number instead"
metadata:
  node_type: memory
  type: feedback
  originSessionId: 5a5b1007-4059-4b74-9ec8-52734257d1e6
  modified: 2026-09-10T04:09:37.327Z
---

If you iteratively `uip rpa pack` a Library project locally under the **same** version number more than once (e.g. testing a fix, then adding more to it, re-packing "1.559.18" again with new content), `uip rpa packages install` in the consuming project will silently keep resolving the **old** cached copy from `C:\Users\<user>\.nuget\packages\<pkg_lowercase>\<version>\`, even after you later publish the real/final content to the Orchestrator tenant feed under that same version number. Symptom: validate/build errors referencing types or activities you know you added, as if the fix were never applied.

**Why:** NuGet's local package cache is a straight version-keyed hit — it does not re-check the remote feed once a local copy for that exact ID+version exists.

**Attempted fix that didn't work:** `rm -rf` the stale cache folder — failed with "Device or resource busy", because the `uip rpa` background headless Studio host (kept warm across calls in the same session, per the skill's Session Pre-warm pattern) holds the DLLs open.

**How to apply:** don't fight the lock. Just bump to a **version number that has never been packed locally in this session**, pack + `uip or libraries upload` that, and point the consuming project's `project.json` at the new number. Cheaper than killing the Studio host process. Also a reminder to give the *real* PR version its own final bump distinct from whatever numbers were used for local test iterations — don't carry test-iteration version numbers into the PR just because they're "the next number in sequence" (see [[project_bt75495_kaiser_delegate_account_login]] for a concrete case: local tests used .18/.19, but the real develop baseline was still .17, so the real PR bump was .17→.18 first, then re-bumped to .20 specifically to dodge this exact cache collision).
