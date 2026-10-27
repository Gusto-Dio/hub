---
name: feedback_buildkite_creds_share_intermittent
description: "Buildkite deploy.ps1 can intermittently fail to reach the Orchestrator creds file share on the agent host, unrelated to code/PR content"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: dc0d2ea7-d67d-4738-a544-e3e8e9009383
  modified: 2026-09-14T13:26:38.558Z
---

Buildkite's `deploy.ps1` step can fail with "Credentials file not found at `\\fs3-prd-aws.gustocorp.com\BizTech\uipath-pipeline-creds.json`. Falling back to environment variables." followed by "Required Orchestrator credentials are missing: CLIENT_ID, CLIENT_SECRET." — this is the Buildkite agent host failing to reach the network share, not a code, config, or PR problem.

**Why:** Confirmed on build #14509 (deploy of PR #3310, `Kaiser_CA_MemberUpdates`, part of [[project_bt75495_kaiser_delegate_account_login]]) — the 6 other deploy builds in the same merge sequence (minutes apart, same agent pool) read the same file successfully. A different, unrelated deploy failure (NuGet package version not yet published, "Unable to find package ... nearest version") had happened the day before (build #14480) on the same process — so this pipeline has more than one flaky-looking failure mode; always read the actual job log before assuming either "it's just flaky" or "it's a real regression."

**How to apply:** if a Buildkite deploy job fails specifically on the credentials-file line (not on `check_version.sh`/`check_dependency.sh`/an actual `uipcli`/build error), treat it as a transient agent/network-share access issue — recommend a plain **Retry** on that job via the Buildkite UI (no MCP tool currently exposes a retry/rebuild trigger). Don't start debugging project.json, dependencylock.json, or Orchestrator credentials themselves unless the retry fails too.

**Update 2026-09-14 — it's always the SAME single machine, not agent-pool luck:** build #14523 (PR #3320,
`Libraries/Gusto_Benefits`, [[project_bt75657_bsca_delegate_account_login]]) needed **5 manual retries**
(job + 4 retries, all identical "Required Orchestrator credentials are missing: CLIENT_ID, CLIENT_SECRET")
before one finally passed. Checked via `list_jobs` with `include_agent=true`: every single one of those
`deploy.ps1` attempts ran on the exact same Buildkite agent — hostname `uscol1-kibana-1`, agent name
`uscol1-kibana-1-1`, Windows Server 2016, queue `uipath`. This is a **single dedicated static Windows
agent**, not an autoscaling pool — unlike `check_version.sh`/`check_dependency.sh` (queue `default`),
which run on ephemeral Linux EC2-spot agents that rotate on every job. So "Retry" does NOT work by landing
on a different, healthier agent — it's the same box every time. The fix is a transient network/SMB blip
on that specific Windows host reaching `\\fs3-prd-aws.gustocorp.com\BizTech\uipath-pipeline-creds.json`,
which can require several retries in a row to clear (took 5 attempts this time, vs. 1 retry on build
#14509). **How to apply (revised):** keep retrying past 1-2 failures — this is a known flaky single-host
issue, not proof of a real problem, even after several attempts. Only escalate to infra about the
`uscol1-kibana-1` agent / SMB share reachability if retries climb into double digits with zero passes.
