# Investigation Rules

## Red Flags — STOP if you think this

| Thought | Reality |
|---|---|
| "Let me look at the code first to get context" | No. Logs first. Always. |
| "I'll ask the user to paste the Orchestrator logs" | No. Pull them yourself with the REST API. |
| "The code looks fine, must be environmental" | Check logs before concluding anything. |
| "I found one suspicious selector, that must be it" | Verify against actual log error messages before proposing a fix. |
| "One faulted job is enough to diagnose" | Check 3+ recent failures — one job may be an outlier. |
| "Let me read the whole process to understand it" | Read only what the error points to. |

## Common Mistakes

| Mistake | Result |
|---|---|
| Read XAML before pulling logs | Wrong root cause — code analysis without runtime context is guessing |
| Use integer job ID instead of GUID for log query | OData filter fails with type mismatch error |
| Fix only the first error in the log | Often masks a second failure downstream — read the full log sequence |
| Conclude from a single faulted job | One job may be an outlier; check 3+ recent failures for pattern |
| Skip recent PRs check | Misses dependency bumps that silently changed selector or activity behavior |
| Propose a Library fix for a process-specific bug | Library changes affect every process — fix at the process level only |
